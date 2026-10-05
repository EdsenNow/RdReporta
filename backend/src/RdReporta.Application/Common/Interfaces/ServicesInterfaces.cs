using System.Security.Claims;
using RdReporta.Domain.Entities;

namespace RdReporta.Application.Common.Interfaces;

public interface IJwtTokenService
{
    string GenerateAccessToken(User user, IEnumerable<string> roles);
    string GenerateRefreshToken();
    ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
}

public interface IPasswordHasher
{
    string Hash(string password);
    bool Verify(string password, string passwordHash);
}

public interface ICurrentUserService
{
    Guid? UserId { get; }
    string? Email { get; }
    bool IsAuthenticated { get; }
}

public interface IStorageService
{
    Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType, Guid ownerUserId, CancellationToken cancellationToken = default);
    Task DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default);
}

public record AppleUserTokenInfo(string Sub, string Email, bool EmailVerified);

public interface IAppleAuthService
{
    Task<AppleUserTokenInfo> ValidateTokenAsync(string identityToken, CancellationToken cancellationToken = default);
}

