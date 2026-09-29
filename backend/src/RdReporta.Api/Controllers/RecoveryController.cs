using System.ComponentModel.DataAnnotations;
using System.Net;
using System.Net.Mail;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Application.Common.Models;

namespace RdReporta.Api.Controllers;

[ApiController]
[Route("api/auth")]
[EnableRateLimiting("auth")]
public class RecoveryController(IApplicationDbContext db, IDataProtectionProvider protection,
    IPasswordHasher hasher, IConfiguration config) : ControllerBase
{
    private readonly ITimeLimitedDataProtector _protector = protection.CreateProtector("RDReporta.PasswordReset.v1").ToTimeLimitedDataProtector();
    private record ResetTicket(Guid UserId, string PasswordVersion);
    private static string Version(string? hash) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(hash ?? "")));

    [HttpPost("forgot-password")]
    public async Task<IActionResult> Forgot(ForgotPasswordRequest request, CancellationToken ct)
    {
        var host = config["Smtp:Host"];
        var from = config["Smtp:From"];
        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(from))
            return StatusCode(503, ApiResponse<bool>.Fail("La recuperación por correo no está disponible todavía."));

        var email = request.Email.Trim().ToLowerInvariant();
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email && u.IsActive, ct);
        if (user != null)
        {
            var token = _protector.Protect(JsonSerializer.Serialize(new ResetTicket(user.Id, Version(user.PasswordHash))), TimeSpan.FromMinutes(20));
            using var message = new MailMessage(from, user.Email, "Recupera tu cuenta RDReporta",
                $"Copia este código en la pantalla de recuperación de RDReporta. Caduca en 20 minutos y solo se puede usar una vez.\n\n{token}\n\nSi no solicitaste este cambio, ignora este correo.");
            using var smtp = new SmtpClient(host, config.GetValue("Smtp:Port", 587))
            {
                EnableSsl = config.GetValue("Smtp:EnableSsl", true),
                UseDefaultCredentials = false
            };
            if (!string.IsNullOrEmpty(config["Smtp:Username"]))
                smtp.Credentials = new NetworkCredential(config["Smtp:Username"], config["Smtp:Password"]);
            try { await smtp.SendMailAsync(message, ct); }
            catch (SmtpException)
            {
                // Preserve the same public response for existing and unknown accounts.
                HttpContext.RequestServices.GetRequiredService<ILogger<RecoveryController>>()
                    .LogError("No se pudo entregar un correo de recuperación. Revisar el servicio SMTP.");
            }
        }
        return Ok(ApiResponse<bool>.Ok(true, "Si la cuenta existe, recibirás un código de recuperación."));
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> Reset(ResetPasswordRequest request, CancellationToken ct)
    {
        ResetTicket? ticket;
        try { ticket = JsonSerializer.Deserialize<ResetTicket>(_protector.Unprotect(request.Token)); }
        catch (Exception e) when (e is CryptographicException or JsonException or FormatException)
        { return BadRequest(ApiResponse<bool>.Fail("El código es inválido o ha caducado.")); }
        var user = ticket == null ? null : await db.Users.FirstOrDefaultAsync(u => u.Id == ticket.UserId && u.IsActive, ct);
        if (user == null || Version(user.PasswordHash) != ticket!.PasswordVersion)
            return BadRequest(ApiResponse<bool>.Fail("El código es inválido o ha caducado."));
        // Conditional update makes consuming the ticket atomic, including concurrent attempts.
        var previousHash = user.PasswordHash;
        var newHash = hasher.Hash(request.Password);
        var changed = await db.Users.Where(u => u.Id == user.Id && u.PasswordHash == previousHash)
            .ExecuteUpdateAsync(s => s.SetProperty(u => u.PasswordHash, newHash)
                .SetProperty(u => u.RefreshToken, (string?)null)
                .SetProperty(u => u.RefreshTokenExpiryTime, (DateTime?)null)
                .SetProperty(u => u.UpdatedAt, DateTime.UtcNow), ct);
        return changed == 1 ? Ok(ApiResponse<bool>.Ok(true, "Contraseña actualizada. Inicia sesión."))
            : BadRequest(ApiResponse<bool>.Fail("El código ya se utilizó."));
    }
}

public record ForgotPasswordRequest([Required, EmailAddress, MaxLength(256)] string Email);
public record ResetPasswordRequest([Required, MaxLength(4096)] string Token, [Required, MinLength(8), MaxLength(72)] string Password);
