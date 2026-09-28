using System.ComponentModel.DataAnnotations;
using RdReporta.Domain.Enums;

namespace RdReporta.Application.DTOs;

public record CategoryDto(
    int Id,
    string Name,
    string Slug,
    string? Description,
    string IconName,
    string ColorHex,
    int DisplayOrder
);

public record CreateCategoryRequest(
    [Required, MaxLength(50)] string Name,
    [Required, MaxLength(60)] string Slug,
    string? Description,
    [Required] string IconName,
    [Required] string ColorHex,
    int DisplayOrder
);

public record CreatePostRequest(
    [Required] int CategoryId,
    [Required, MaxLength(150)] string Title,
    [Required] string Description,
    [Required] double Latitude,
    [Required] double Longitude,
    [Required] string Province,
    [Required] string Municipality,
    string? AddressReference,
    List<string>? ImageUrls
);

public record PostDto(
    Guid Id,
    Guid UserId,
    string AuthorUsername,
    string? AuthorAvatarUrl,
    ReputationLevel AuthorReputation,
    int CategoryId,
    string CategoryName,
    string CategoryIcon,
    string CategoryColor,
    string Title,
    string Description,
    double Latitude,
    double Longitude,
    string Province,
    string Municipality,
    string? AddressReference,
    PostStatus Status,
    int ViewsCount,
    int ReactionsCount,
    int ConfirmationsCount,
    List<string> Images,
    DateTime CreatedAt,
    double? DistanceInMeters = null,
    bool UserHasConfirmed = false,
    ReactionType? UserReaction = null
);

public record PostMapPinDto(
    Guid Id,
    double Latitude,
    double Longitude,
    int CategoryId,
    string CategoryName,
    string CategoryColor,
    string Title,
    string? ThumbnailUrl,
    int ConfirmationsCount,
    DateTime CreatedAt
);

public record NearbyPostsRequest(
    [Required] double Latitude,
    [Required] double Longitude,
    double RadiusKm = 10.0,
    int? CategoryId = null,
    int PageNumber = 1,
    int PageSize = 20
);

public record PostReactionRequest(
    [Required] ReactionType ReactionType
);

public record PostConfirmationRequest(
    double? Latitude,
    double? Longitude
);

public record CreateModerationReportRequest(
    [Required] Guid PostId,
    [Required] ModerationReason Reason,
    string? Description
);

public record ModerationReportDto(
    Guid Id,
    Guid PostId,
    string PostTitle,
    Guid ReporterUserId,
    string ReporterUsername,
    ModerationReason Reason,
    string? Description,
    ModerationStatus Status,
    DateTime CreatedAt,
    string? ResolutionNotes
);

public record ResolveModerationRequest(
    [Required] ModerationStatus Status,
    string? ResolutionNotes,
    bool HidePost = false
);
