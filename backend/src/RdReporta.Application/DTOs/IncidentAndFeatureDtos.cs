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
    [Required, MaxLength(50)] string IconName,
    [Required, RegularExpression("^#[0-9a-fA-F]{6}$")] string ColorHex,
    int DisplayOrder
);

public record CreatePostRequest(
    [Required] int CategoryId,
    [Required, MaxLength(150)] string Title,
    [Required, MaxLength(5000)] string Description,
    [Range(-90, 90)] double Latitude,
    [Range(-180, 180)] double Longitude,
    [Required, MaxLength(100)] string Province,
    [Required, MaxLength(100)] string Municipality,
    [MaxLength(100)] string? Neighborhood,
    [MaxLength(255)] string? AddressReference,
    [MaxLength(4)] List<string>? ImageUrls
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
    string? Neighborhood,
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
    [Range(-90, 90)] double Latitude,
    [Range(-180, 180)] double Longitude,
    [Range(0.1, 100)] double RadiusKm = 10.0,
    int? CategoryId = null,
    [Range(1, int.MaxValue)] int PageNumber = 1,
    [Range(1, 100)] int PageSize = 20
);

public record PostReactionRequest(
    [EnumDataType(typeof(ReactionType))] ReactionType ReactionType
);

public record PostConfirmationRequest(
    [Range(-90, 90)] double? Latitude,
    [Range(-180, 180)] double? Longitude
);

public record CreateModerationReportRequest(
    [Required] Guid PostId,
    [EnumDataType(typeof(ModerationReason))] ModerationReason Reason,
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
