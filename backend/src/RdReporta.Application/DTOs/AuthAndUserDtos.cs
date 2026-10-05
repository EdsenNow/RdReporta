using System.ComponentModel.DataAnnotations;
using RdReporta.Domain.Enums;

namespace RdReporta.Application.DTOs;

public record RegisterRequest(
    [Required, MinLength(3), MaxLength(50)] string Username,
    [Required, EmailAddress] string Email,
    [Required, MinLength(8), MaxLength(72),
     RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$",
         ErrorMessage = "La contraseña debe incluir mayúscula, minúscula y número.")] string Password,
    [MaxLength(100)] string? Province,
    [MaxLength(100)] string? Municipality
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
    string DisplayName,
    string? AvatarUrl,
    string? Province,
    string? Municipality,
    int ReputationScore,
    ReputationLevel ReputationLevel,
    int TotalPosts,
    DateTime MemberSince,
    DateTime? UsernameCanChangeAt,
    bool IsVerified,
    int FollowersCount,
    int FollowingCount,
    bool IsFollowing
);

public record NotificationDto(Guid Id, Guid ActorUserId, Guid? PostId, string Type,
    string Message, bool IsRead, DateTime CreatedAt);

public record UpdateProfileRequest(
    string? AvatarUrl,
    [MinLength(2), MaxLength(80)] string? DisplayName,
    [MinLength(3), MaxLength(30)] string? Username,
    [MaxLength(100)] string? Province,
    [MaxLength(100)] string? Municipality
);
