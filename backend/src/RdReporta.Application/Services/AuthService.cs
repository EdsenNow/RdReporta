using Microsoft.EntityFrameworkCore;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Application.Common.Models;
using RdReporta.Application.DTOs;
using RdReporta.Domain.Entities;
using RdReporta.Domain.Enums;

namespace RdReporta.Application.Services;

public interface IAuthService
{
    Task<ApiResponse<AuthResponse>> RegisterAsync(RegisterRequest request, CancellationToken ct = default);
    Task<ApiResponse<AuthResponse>> LoginAsync(LoginRequest request, CancellationToken ct = default);
    Task<ApiResponse<AuthResponse>> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken ct = default);
}

public class AuthService : IAuthService
{
    private readonly IApplicationDbContext _context;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _jwtTokenService;

    public AuthService(
        IApplicationDbContext context,
        IPasswordHasher passwordHasher,
        IJwtTokenService jwtTokenService)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _jwtTokenService = jwtTokenService;
    }

    public async Task<ApiResponse<AuthResponse>> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var normalizedUsername = request.Username.Trim().ToLowerInvariant();

        if (await _context.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail, ct))
        {
            return ApiResponse<AuthResponse>.Fail("El correo electrónico ya se encuentra registrado.");
        }

        if (await _context.Users.AnyAsync(u => u.Username.ToLower() == normalizedUsername, ct))
        {
            return ApiResponse<AuthResponse>.Fail("El nombre de usuario ya está en uso.");
        }

        var defaultRole = await _context.Roles.FirstOrDefaultAsync(r => r.Name == "Ciudadano", ct);
        if (defaultRole == null)
        {
            defaultRole = new Role { Name = "Ciudadano" };
            _context.Roles.Add(defaultRole);
            await _context.SaveChangesAsync(ct);
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = request.Username.Trim(),
            Email = normalizedEmail,
            PasswordHash = _passwordHasher.Hash(request.Password),
            Province = request.Province,
            Municipality = request.Municipality,
            ReputationScore = 100,
            ReputationLevel = ReputationLevel.Ciudadano,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        user.UserRoles.Add(new UserRole { User = user, Role = defaultRole });

        var roles = new List<string> { "Ciudadano" };
        var accessToken = _jwtTokenService.GenerateAccessToken(user, roles);
        var refreshToken = _jwtTokenService.GenerateRefreshToken();

        user.RefreshToken = refreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(14);

        _context.Users.Add(user);
        await _context.SaveChangesAsync(ct);

        var response = new AuthResponse(
            user.Id,
            user.Username,
            user.Email,
            accessToken,
            refreshToken,
            DateTime.UtcNow.AddHours(2),
            roles,
            user.ReputationLevel
        );

        return ApiResponse<AuthResponse>.Ok(response, "Usuario registrado exitosamente.");
    }

    public async Task<ApiResponse<AuthResponse>> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var user = await _context.Users
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail, ct);

        if (user == null || string.IsNullOrEmpty(user.PasswordHash) || !_passwordHasher.Verify(request.Password, user.PasswordHash))
        {
            return ApiResponse<AuthResponse>.Fail("Credenciales inválidas.");
        }

        if (!user.IsActive)
        {
            return ApiResponse<AuthResponse>.Fail("Esta cuenta ha sido suspendida.");
        }

        var roles = user.UserRoles.Select(ur => ur.Role.Name).ToList();
        if (roles.Count == 0) roles.Add("Ciudadano");

        var accessToken = _jwtTokenService.GenerateAccessToken(user, roles);
        var refreshToken = _jwtTokenService.GenerateRefreshToken();

        user.RefreshToken = refreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(14);
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(ct);

        var response = new AuthResponse(
            user.Id,
            user.Username,
            user.Email,
            accessToken,
            refreshToken,
            DateTime.UtcNow.AddHours(2),
            roles,
            user.ReputationLevel
        );

        return ApiResponse<AuthResponse>.Ok(response, "Inicio de sesión exitoso.");
    }

    public async Task<ApiResponse<AuthResponse>> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken ct = default)
    {
        var principal = _jwtTokenService.GetPrincipalFromExpiredToken(request.AccessToken);
        if (principal == null)
        {
            return ApiResponse<AuthResponse>.Fail("Token de acceso inválido.");
        }

        var userIdClaim = principal.Claims.FirstOrDefault(c => c.Type == "sub" || c.Type == System.Security.Claims.ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
        {
            return ApiResponse<AuthResponse>.Fail("Identificador de usuario inválido en token.");
        }

        var user = await _context.Users
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user == null || user.RefreshToken != request.RefreshToken || user.RefreshTokenExpiryTime <= DateTime.UtcNow)
        {
            return ApiResponse<AuthResponse>.Fail("Refresh token inválido o expirado.");
        }

        var roles = user.UserRoles.Select(ur => ur.Role.Name).ToList();
        if (roles.Count == 0) roles.Add("Ciudadano");

        var newAccessToken = _jwtTokenService.GenerateAccessToken(user, roles);
        var newRefreshToken = _jwtTokenService.GenerateRefreshToken();

        user.RefreshToken = newRefreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(14);
        await _context.SaveChangesAsync(ct);

        var response = new AuthResponse(
            user.Id,
            user.Username,
            user.Email,
            newAccessToken,
            newRefreshToken,
            DateTime.UtcNow.AddHours(2),
            roles,
            user.ReputationLevel
        );

        return ApiResponse<AuthResponse>.Ok(response, "Sesión renovada exitosamente.");
    }
}
