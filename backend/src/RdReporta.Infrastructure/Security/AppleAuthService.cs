using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using RdReporta.Application.Common.Interfaces;

namespace RdReporta.Infrastructure.Security;

public class AppleAuthService : IAppleAuthService
{
    private const string AppleIssuer = "https://appleid.apple.com";
    private const string AppleJwksUrl = "https://appleid.apple.com/auth/keys";
    private static readonly TimeSpan KeyCacheDuration = TimeSpan.FromHours(24);

    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AppleAuthService> _logger;

    private static readonly SemaphoreSlim _keyLock = new(1, 1);
    private static JsonWebKeySet? _cachedKeySet;
    private static DateTime _keySetExpiresAt = DateTime.MinValue;

    public AppleAuthService(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<AppleAuthService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<AppleUserTokenInfo> ValidateTokenAsync(string identityToken, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(identityToken))
        {
            throw new ArgumentException("El token de identidad de Apple es requerido.", nameof(identityToken));
        }

        var handler = new JwtSecurityTokenHandler();
        if (!handler.CanReadToken(identityToken))
        {
            throw new SecurityTokenValidationException("El formato del token de identidad de Apple no es válido.");
        }

        var jwt = handler.ReadJwtToken(identityToken);
        var keyId = jwt.Header.Kid;
        if (string.IsNullOrEmpty(keyId))
        {
            throw new SecurityTokenValidationException("El token de Apple no incluye el identificador de clave (kid).");
        }

        var keySet = await GetSigningKeysAsync(keyId, cancellationToken);
        var signingKey = keySet.Keys.FirstOrDefault(k => k.Kid == keyId)
            ?? throw new SecurityTokenValidationException("No se encontró la clave pública de Apple para validar la firma.");

        var audiences = GetValidAudiences();

        var validationParameters = new TokenValidationParameters
        {
            ValidIssuer = AppleIssuer,
            ValidateIssuer = true,
            IssuerSigningKey = signingKey,
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true,
            ValidateAudience = audiences.Count > 0,
            ValidAudiences = audiences,
            ClockSkew = TimeSpan.FromMinutes(5)
        };

        ClaimsPrincipal principal;
        try
        {
            principal = handler.ValidateToken(identityToken, validationParameters, out _);
        }
        catch (SecurityTokenException ex)
        {
            _logger.LogWarning(ex, "Fallo al validar token de Apple.");
            throw;
        }

        var sub = principal.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? principal.FindFirstValue("sub")
            ?? throw new SecurityTokenValidationException("El token de Apple no contiene el identificador de usuario (sub).");

        var email = principal.FindFirstValue(ClaimTypes.Email)
            ?? principal.FindFirstValue("email");

        var emailVerifiedClaim = principal.FindFirstValue("email_verified");
        var emailVerified = true;
        if (!string.IsNullOrEmpty(emailVerifiedClaim) &&
            bool.TryParse(emailVerifiedClaim, out var parsedVerified))
        {
            emailVerified = parsedVerified;
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            // Apple does not return the email in subsequent logins if the user already authorized the app.
            // In that case, we generate a deterministic email mapped to their unique Apple subject ID.
            email = $"{sub.ToLowerInvariant()}@privaterelay.appleid.com";
        }

        return new AppleUserTokenInfo(sub, email, emailVerified);
    }

    private List<string> GetValidAudiences()
    {
        var audiences = new HashSet<string>(StringComparer.Ordinal);

        var bundleId = _configuration["Authentication:AppleBundleId"];
        if (!string.IsNullOrWhiteSpace(bundleId))
        {
            audiences.Add(bundleId.Trim());
        }

        var clientId = _configuration["Authentication:AppleClientId"];
        if (!string.IsNullOrWhiteSpace(clientId))
        {
            audiences.Add(clientId.Trim());
        }

        var additional = _configuration["Authentication:AppleAudiences"];
        if (!string.IsNullOrWhiteSpace(additional))
        {
            foreach (var aud in additional.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                audiences.Add(aud);
            }
        }

        // Fallback default for RDReporta iOS app
        if (audiences.Count == 0)
        {
            audiences.Add("com.rdreporta.app");
        }

        return audiences.ToList();
    }

    private async Task<JsonWebKeySet> GetSigningKeysAsync(string targetKid, CancellationToken ct)
    {
        if (_cachedKeySet != null && DateTime.UtcNow < _keySetExpiresAt && _cachedKeySet.Keys.Any(k => k.Kid == targetKid))
        {
            return _cachedKeySet;
        }

        await _keyLock.WaitAsync(ct);
        try
        {
            if (_cachedKeySet != null && DateTime.UtcNow < _keySetExpiresAt && _cachedKeySet.Keys.Any(k => k.Kid == targetKid))
            {
                return _cachedKeySet;
            }

            var json = await _httpClient.GetStringAsync(AppleJwksUrl, ct);
            var keySet = new JsonWebKeySet(json);

            _cachedKeySet = keySet;
            _keySetExpiresAt = DateTime.UtcNow.Add(KeyCacheDuration);

            return keySet;
        }
        finally
        {
            _keyLock.Release();
        }
    }
}
