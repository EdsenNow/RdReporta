using System.ComponentModel.DataAnnotations;
using RdReporta.Domain.Enums;

namespace RdReporta.Application.DTOs;

public record RegisterRequest(
    [Required, MinLength(3), MaxLength(50)] string Username,
    [Required, EmailAddress] string Email,
    [Required, MinLength(6)] string Password,
    string? Province,
    string? Municipality
);

public record LoginRequest(
    [Required, EmailAddress] string Email,
    [Required] string Password
);

public record AuthResponse(
    Guid UserId,
    string Username,
    string Email,
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAt,
    List<string> Roles,
    ReputationLevel ReputationLevel
);

public record RefreshTokenRequest(
    [Required] string AccessToken,
    [Required] string RefreshToken
);

public record UserProfileDto(
    Guid Id,
    string Username,
    string Email,
    string? AvatarUrl,
    string? Province,
    string? Municipality,
    int ReputationScore,
    ReputationLevel ReputationLevel,
    int TotalPosts,
    int TotalConfirmationsReceived,
    DateTime MemberSince
);

public record UpdateProfileRequest(
    string? AvatarUrl,
    string? Province,
    string? Municipality
);
