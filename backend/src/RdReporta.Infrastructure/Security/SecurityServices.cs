using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Domain.Entities;

namespace RdReporta.Infrastructure.Security;

public class PasswordHasher : IPasswordHasher
{
    public string Hash(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password, workFactor: 11);
    }

    public bool Verify(string password, string passwordHash)
    {
        return BCrypt.Net.BCrypt.Verify(password, passwordHash);
    }
}

public class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _configuration;

    public JwtTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GenerateAccessToken(User user, IEnumerable<string> roles)
    {
        var secretKey = _configuration["Jwt:SecretKey"] ?? "RDReporta_UltraSecure_SuperSecretKey_2026_DevOnly!@#";
        var issuer = _configuration["Jwt:Issuer"] ?? "RDReportaApi";
        var audience = _configuration["Jwt:Audience"] ?? "RDReportaApp";
        var expiryHours = int.TryParse(_configuration["Jwt:ExpiryInHours"], out var hours) ? hours : 2;

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(JwtRegisteredClaimNames.UniqueName, user.Username),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new("reputation", user.ReputationLevel.ToString())
        };

        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddHours(expiryHours),
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = credentials
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        var randomNumber = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }

    public ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
    {
        var secretKey = _configuration["Jwt:SecretKey"] ?? "RDReporta_UltraSecure_SuperSecretKey_2026_DevOnly!@#";

        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = true,
            ValidAudience = _configuration["Jwt:Audience"] ?? "RDReportaApp",
            ValidateIssuer = true,
            ValidIssuer = _configuration["Jwt:Issuer"] ?? "RDReportaApi",
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
            ValidateLifetime = false // Here we don't care about lifetime because we want to validate expired token to refresh it
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        ClaimsPrincipal principal;
        SecurityToken securityToken;
        try { principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out securityToken); }
        catch (Exception e) when (e is SecurityTokenException or ArgumentException) { return null; }

        if (securityToken is not JwtSecurityToken jwtSecurityToken ||
            !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
        {
            return null;
        }

        return principal;
    }
}
