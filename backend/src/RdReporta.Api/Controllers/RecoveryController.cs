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
using RdReporta.Domain.Entities;

namespace RdReporta.Api.Controllers;

[ApiController]
[Route("api/auth")]
[EnableRateLimiting("auth")]
public class RecoveryController(
    IApplicationDbContext db,
    IDataProtectionProvider protection,
    IPasswordHasher hasher,
    IConfiguration config,
    IWebHostEnvironment env,
    ILogger<RecoveryController> logger) : ControllerBase
{
    private readonly ITimeLimitedDataProtector _protector = protection.CreateProtector("RDReporta.PasswordReset.v1").ToTimeLimitedDataProtector();
    private record ResetTicket(Guid UserId, string PasswordVersion);
    private static string Version(string? hash) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(hash ?? "")));

    [HttpPost("forgot-password")]
    public async Task<IActionResult> Forgot(ForgotPasswordRequest request, CancellationToken ct)
    {
        var host = config["Smtp:Host"];
        var from = config["Smtp:From"];
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email && u.IsActive, ct);

        if (user != null)
        {
            // Generar código numérico de 6 dígitos legible (ej. 482910)
            var pinCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
            user.PasswordResetCode = pinCode;
            user.PasswordResetExpiresAt = DateTime.UtcNow.AddMinutes(20);
            await db.SaveChangesAsync(ct);

            var token = _protector.Protect(JsonSerializer.Serialize(new ResetTicket(user.Id, Version(user.PasswordHash))), TimeSpan.FromMinutes(20));

            if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(from))
            {
                if (env.IsDevelopment())
                {
                    logger.LogWarning("""

                        ================================================================================
                        [RECUPERACIÓN DE CONTRASEÑA - DESARROLLO (SMTP no configurado)]
                        Usuario: {Email}
                        Código PIN de 6 dígitos: {PinCode}
                        Token alternativo: {Token}
                        ================================================================================
                        """, user.Email, pinCode, token);
                    return Ok(ApiResponse<bool>.Ok(true, "Código generado en consola de desarrollo."));
                }
                return StatusCode(503, ApiResponse<bool>.Fail("La recuperación por correo no está disponible todavía."));
            }

            var htmlBody = $$"""
                <!DOCTYPE html>
                <html>
                <head>
                  <meta charset="utf-8">
                  <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #191724; color: #e0def4; margin: 0; padding: 24px; }
                    .card { max-width: 500px; margin: 0 auto; background: #1f1d2e; border: 1px solid rgba(255,255,255,0.08); border-radius: 18px; padding: 32px; text-align: center; }
                    .logo { font-size: 26px; font-weight: 900; color: #eb6f92; margin-bottom: 8px; letter-spacing: 1.5px; }
                    .title { font-size: 20px; font-weight: bold; color: #ffffff; margin-bottom: 12px; }
                    .desc { font-size: 14px; line-height: 1.6; color: #908caa; margin-bottom: 24px; text-align: left; }
                    .pin-box { background: #26233a; border: 2px dashed #eb6f92; border-radius: 14px; padding: 18px 24px; font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: 900; letter-spacing: 8px; color: #f6c177; margin: 20px 0; text-align: center; user-select: all; }
                    .notice { font-size: 12px; color: #6e6a86; line-height: 1.5; border-top: 1px solid rgba(255,255,255,0.06); padding-top: 18px; margin-top: 24px; text-align: left; }
                  </style>
                </head>
                <body>
                  <div class="card">
                    <div class="logo">RDREPORTA</div>
                    <div class="title">Recupera tu cuenta</div>
                    <div class="desc">
                      Hemos recibido una solicitud para restablecer la contraseña de tu cuenta.
                      Introduce el siguiente código en la aplicación:
                    </div>
                    <div class="pin-box">{{pinCode}}</div>
                    <div style="font-size: 13px; color: #908caa; margin-bottom: 16px;">
                      ⏱️ Este código caduca en <strong>20 minutos</strong> y es de un solo uso.
                    </div>
                    <div class="notice">
                      Si no solicitaste este cambio, puedes ignorar este correo de forma segura. Tu cuenta no sufrirá modificaciones.
                    </div>
                  </div>
                </body>
                </html>
                """;

            var senderAddress = from.Contains('<') ? from : $"RDReporta <{from}>";
            using var message = new MailMessage(senderAddress, user.Email)
            {
                Subject = $"Tu código de recuperación de RDReporta es {pinCode}",
                Body = htmlBody,
                IsBodyHtml = true
            };
            message.AlternateViews.Add(AlternateView.CreateAlternateViewFromString(
                $"Tu código de recuperación de RDReporta es: {pinCode}\n\nCaduca en 20 minutos y solo se puede usar una vez.\nSi no solicitaste este cambio, ignora este correo.",
                null, "text/plain"));

            using var smtp = new SmtpClient(host, config.GetValue("Smtp:Port", 587))
            {
                EnableSsl = config.GetValue("Smtp:EnableSsl", true),
                UseDefaultCredentials = false
            };
            if (!string.IsNullOrEmpty(config["Smtp:Username"]))
                smtp.Credentials = new NetworkCredential(config["Smtp:Username"], config["Smtp:Password"]);

            try { await smtp.SendMailAsync(message, ct); }
            catch (Exception ex)
            {
                logger.LogError(ex, "No se pudo entregar el correo de recuperación vía SMTP ({Host}).", host);
            }
        }
        return Ok(ApiResponse<bool>.Ok(true, "Si la cuenta existe, recibirás un código de recuperación."));
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> Reset(ResetPasswordRequest request, CancellationToken ct)
    {
        var inputCode = request.Token.Trim();
        User? user = null;

        // 1. Verificación por código numérico de 6 dígitos
        if (inputCode.Length == 6 && int.TryParse(inputCode, out _))
        {
            user = await db.Users.FirstOrDefaultAsync(u =>
                u.PasswordResetCode == inputCode &&
                u.PasswordResetExpiresAt > DateTime.UtcNow &&
                u.IsActive, ct);

            if (user == null)
                return BadRequest(ApiResponse<bool>.Fail("El código de 6 dígitos es incorrecto o ha caducado."));
        }
        else
        {
            // 2. Soporte retrocompatible para token largo cifrado
            ResetTicket? ticket;
            try { ticket = JsonSerializer.Deserialize<ResetTicket>(_protector.Unprotect(inputCode)); }
            catch (Exception e) when (e is CryptographicException or JsonException or FormatException)
            { return BadRequest(ApiResponse<bool>.Fail("El código es inválido o ha caducado.")); }

            user = ticket == null ? null : await db.Users.FirstOrDefaultAsync(u => u.Id == ticket.UserId && u.IsActive, ct);
            if (user == null || Version(user.PasswordHash) != ticket!.PasswordVersion)
                return BadRequest(ApiResponse<bool>.Fail("El código es inválido o ha caducado."));
        }

        var newHash = hasher.Hash(request.Password);
        var changed = await db.Users.Where(u => u.Id == user.Id)
            .ExecuteUpdateAsync(s => s.SetProperty(u => u.PasswordHash, newHash)
                .SetProperty(u => u.PasswordResetCode, (string?)null)
                .SetProperty(u => u.PasswordResetExpiresAt, (DateTime?)null)
                .SetProperty(u => u.RefreshToken, (string?)null)
                .SetProperty(u => u.RefreshTokenExpiryTime, (DateTime?)null)
                .SetProperty(u => u.UpdatedAt, DateTime.UtcNow), ct);

        return changed == 1 ? Ok(ApiResponse<bool>.Ok(true, "Contraseña actualizada con éxito. Ya puedes iniciar sesión."))
            : BadRequest(ApiResponse<bool>.Fail("No se pudo actualizar la contraseña. Inténtalo de nuevo."));
    }
}

public record ForgotPasswordRequest([Required, EmailAddress, MaxLength(256)] string Email);
public record ResetPasswordRequest(
    [Required, MaxLength(4096)] string Token,
    [Required, MinLength(8), MaxLength(72),
     RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$",
         ErrorMessage = "La contraseña debe incluir mayúscula, minúscula y número.")] string Password);
