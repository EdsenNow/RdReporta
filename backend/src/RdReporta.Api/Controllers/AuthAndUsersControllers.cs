using Microsoft.AspNetCore.Authorization;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Application.DTOs;
using RdReporta.Application.Services;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using RdReporta.Application.Common.Models;
using Google.Apis.Auth;
using Microsoft.IdentityModel.Tokens;

namespace RdReporta.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[EnableRateLimiting("auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly IConfiguration _configuration;

    public AuthController(IAuthService authService, IConfiguration configuration)
    {
        _authService = authService;
        _configuration = configuration;
    }

    [HttpPost("google")]
    public async Task<IActionResult> Google([FromBody] GoogleLoginRequest request, CancellationToken ct)
    {
        var clientId = _configuration["Authentication:GoogleClientId"];
        if (string.IsNullOrWhiteSpace(clientId))
            return StatusCode(503, ApiResponse<AuthResponse>.Fail("Google Sign-In no está configurado en el servidor."));
        try
        {
            var payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken,
                new GoogleJsonWebSignature.ValidationSettings { Audience = [clientId] });
            if (payload.EmailVerified != true)
                return Unauthorized(ApiResponse<AuthResponse>.Fail("Google no confirmó el correo electrónico."));
            var response = await _authService.ExternalLoginAsync(payload.Email, payload.Name ?? payload.Email,
                payload.Picture, ct);
            return response.Success ? Ok(response) : BadRequest(response);
        }
        catch (InvalidJwtException)
        {
            return Unauthorized(ApiResponse<AuthResponse>.Fail("Token de Google inválido o vencido."));
        }
        catch (FormatException)
        {
            return Unauthorized(ApiResponse<AuthResponse>.Fail("Google entregó un token de identidad con formato inválido."));
        }
        catch (HttpRequestException)
        {
            return StatusCode(503, ApiResponse<AuthResponse>.Fail("El servidor no pudo comunicarse con Google para validar la cuenta."));
        }
    }

    [HttpPost("apple")]
    public async Task<IActionResult> Apple(
        [FromBody] AppleLoginRequest request,
        [FromServices] IAppleAuthService appleAuthService,
        CancellationToken ct)
    {
        try
        {
            var tokenInfo = await appleAuthService.ValidateTokenAsync(request.IdentityToken, ct);
            if (!tokenInfo.EmailVerified)
                return Unauthorized(ApiResponse<AuthResponse>.Fail("Apple no confirmó el correo electrónico."));

            var displayName = !string.IsNullOrWhiteSpace(request.FullName)
                ? request.FullName.Trim()
                : tokenInfo.Email;

            var response = await _authService.ExternalLoginAsync(
                tokenInfo.Email, displayName, null, "Apple", ct);

            return response.Success ? Ok(response) : BadRequest(response);
        }
        catch (SecurityTokenValidationException ex)
        {
            return Unauthorized(ApiResponse<AuthResponse>.Fail($"Token de Apple inválido o vencido: {ex.Message}"));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<AuthResponse>.Fail(ex.Message));
        }
        catch (HttpRequestException)
        {
            return StatusCode(503, ApiResponse<AuthResponse>.Fail("El servidor no pudo comunicarse con Apple para validar la cuenta."));
        }
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request, CancellationToken ct)
    {
        var response = await _authService.RegisterAsync(request, ct);
        if (!response.Success) return BadRequest(response);
        return Ok(response);
    }

    [HttpGet("temphash")]
    public IActionResult TempHash([FromServices] RdReporta.Application.Common.Interfaces.IPasswordHasher hasher)
    {
        return Ok(hasher.Hash("Admin12345!"));
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request, CancellationToken ct)
    {
        var response = await _authService.LoginAsync(request, ct);
        if (!response.Success) return Unauthorized(response);
        return Ok(response);
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request, CancellationToken ct)
    {
        var response = await _authService.RefreshTokenAsync(request, ct);
        if (!response.Success) return BadRequest(response);
        return Ok(response);
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout([FromServices] IApplicationDbContext db,
        [FromServices] ICurrentUserService current, CancellationToken ct)
    {
        await db.Users.Where(u => u.Id == current.UserId).ExecuteUpdateAsync(s => s
            .SetProperty(u => u.RefreshToken, (string?)null)
            .SetProperty(u => u.RefreshTokenExpiryTime, (DateTime?)null), ct);
        return Ok(ApiResponse<bool>.Ok(true));
    }
}

public record GoogleLoginRequest([Required] string IdToken);
public record AppleLoginRequest([Required] string IdentityToken, string? FullName = null);

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IApplicationDbContext _db;

    public UsersController(IUserService userService, ICurrentUserService currentUserService, IApplicationDbContext db)
    {
        _userService = userService;
        _currentUserService = currentUserService;
        _db = db;
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetCurrentUserProfile(CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _userService.GetProfileAsync(_currentUserService.UserId.Value, ct);
        if (!response.Success) return NotFound(response);
        return Ok(response);
    }

    [Authorize]
    [HttpPatch("me")]
    public async Task<IActionResult> UpdateCurrentUserProfile([FromBody] UpdateProfileRequest request, CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _userService.UpdateProfileAsync(_currentUserService.UserId.Value, request, ct);
        if (!response.Success) return BadRequest(response);
        return Ok(response);
    }

    [Authorize]
    [HttpDelete("me")]
    public async Task<IActionResult> DeleteCurrentUserAccount(CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _userService.DeleteAccountAsync(_currentUserService.UserId.Value, ct);
        if (!response.Success) return BadRequest(response);
        return Ok(response);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetUserProfile(Guid id, CancellationToken ct)
    {
        var response = await _userService.GetProfileAsync(id, ct);
        if (!response.Success) return NotFound(response);
        if (_currentUserService.UserId != id && response.Data != null)
            response.Data = response.Data with
            {
                IsFollowing = _currentUserService.UserId.HasValue &&
                    await _db.UserFollows.AnyAsync(x => x.FollowerId == _currentUserService.UserId.Value && x.FollowedId == id, ct)
            };
        return Ok(response);
    }

    [Authorize]
    [HttpPost("{id:guid}/follow")]
    public async Task<IActionResult> ToggleFollow(Guid id, CancellationToken ct)
    {
        var currentId = _currentUserService.UserId!.Value;
        if (id == currentId) return BadRequest(ApiResponse<bool>.Fail("No puedes seguirte a ti mismo."));
        if (!await _db.Users.AnyAsync(x => x.Id == id && x.IsActive, ct))
            return NotFound(ApiResponse<bool>.Fail("Perfil no encontrado."));

        var follow = await _db.UserFollows.FirstOrDefaultAsync(x => x.FollowerId == currentId && x.FollowedId == id, ct);
        var isFollowing = follow == null;
        if (follow == null)
            _db.UserFollows.Add(new RdReporta.Domain.Entities.UserFollow { FollowerId = currentId, FollowedId = id });
        else
            _db.UserFollows.Remove(follow);
        await _db.SaveChangesAsync(ct);
        return Ok(ApiResponse<bool>.Ok(isFollowing));
    }

    [HttpGet("{id:guid}/posts")]
    public async Task<IActionResult> UserPosts(Guid id, [FromQuery] int page = 1, CancellationToken ct = default)
    {
        const int pageSize = 20;
        var posts = await _db.Posts.AsNoTracking()
            .Include(x => x.User).Include(x => x.Category).Include(x => x.Images)
            .Include(x => x.Reactions)
            .Where(x => x.UserId == id && x.Status != RdReporta.Domain.Enums.PostStatus.Hidden)
            .OrderByDescending(x => x.CreatedAt).Skip((Math.Max(page, 1) - 1) * pageSize).Take(pageSize)
            .ToListAsync(ct);
        var items = posts.Select(x => PostService.MapToDto(x, x.User, x.Category, _currentUserService.UserId)).ToList();
        return Ok(ApiResponse<List<PostDto>>.Ok(items));
    }
}

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationsController(IApplicationDbContext db, ICurrentUserService current) : ControllerBase
{
    [HttpPost("devices")]
    public async Task<IActionResult> RegisterDevice(RegisterDeviceRequest request, CancellationToken ct)
    {
        var token = request.Token.Trim();
        var item = await db.DeviceRegistrations.FirstOrDefaultAsync(x => x.Token == token, ct);
        if (item == null)
            db.DeviceRegistrations.Add(new RdReporta.Domain.Entities.DeviceRegistration
                { UserId = current.UserId!.Value, Token = request.Token.Trim(), Platform = request.Platform.Trim() });
        else
        {
            item.UserId = current.UserId!.Value;
            item.Platform = request.Platform.Trim();
            item.UpdatedAt = DateTime.UtcNow;
        }
        await db.SaveChangesAsync(ct);
        return Ok(ApiResponse<bool>.Ok(true));
    }
    [HttpDelete("devices")]
    public async Task<IActionResult> UnregisterDevice([FromBody] UnregisterDeviceRequest request, CancellationToken ct)
    {
        await db.DeviceRegistrations.Where(x => x.UserId == current.UserId && x.Token == request.Token.Trim())
            .ExecuteDeleteAsync(ct);
        return Ok(ApiResponse<bool>.Ok(true));
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> UnreadCount(CancellationToken ct) =>
        Ok(ApiResponse<int>.Ok(await db.UserNotifications.CountAsync(
            x => x.UserId == current.UserId && !x.IsRead, ct)));

    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken ct, [FromQuery] int page = 1)
    {
        var userId = current.UserId!.Value;
        var items = await db.UserNotifications.AsNoTracking().Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt).ThenByDescending(x => x.Id)
            .Skip((Math.Clamp(page, 1, 100000) - 1) * 50).Take(50)
            .Select(x => new NotificationDto(x.Id, x.ActorUserId, x.PostId, x.Type, x.Message, x.IsRead, x.CreatedAt))
            .ToListAsync(ct);
        return Ok(ApiResponse<List<NotificationDto>>.Ok(items));
    }

    [HttpPost("read")]
    public async Task<IActionResult> MarkRead([FromBody] MarkNotificationsReadRequest request, CancellationToken ct)
    {
        await db.UserNotifications.Where(x => x.UserId == current.UserId && !x.IsRead && request.Ids.Contains(x.Id))
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.IsRead, true), ct);
        return Ok(ApiResponse<bool>.Ok(true));
    }
}

public record RegisterDeviceRequest([Required, MaxLength(500)] string Token,
    [Required, MaxLength(20)] string Platform);
public record UnregisterDeviceRequest([Required, MaxLength(500)] string Token);
public record MarkNotificationsReadRequest([Required, MaxLength(50)] Guid[] Ids);
