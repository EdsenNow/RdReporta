using NetTopologySuite.Geometries;
using RdReporta.Domain.Enums;

namespace RdReporta.Domain.Entities;

public class Post : BaseEntity<Guid>
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public int CategoryId { get; set; }
    public Category Category { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;

    // Spatial coordinate using NetTopologySuite (SRID 4326 - WGS84)
    public Point LocationCoordinates { get; set; } = null!;
    public double Latitude { get; set; }
    public double Longitude { get; set; }

    public string Province { get; set; } = string.Empty;
    public string Municipality { get; set; } = string.Empty;
    public string? Neighborhood { get; set; }
    public string? AddressReference { get; set; }

    public PostStatus Status { get; set; } = PostStatus.Active;
    public int ViewsCount { get; set; } = 0;
    public int ReactionsCount { get; set; } = 0;
    public int ConfirmationsCount { get; set; } = 0;

    // Navigations
    public ICollection<PostImage> Images { get; set; } = new List<PostImage>();
    public ICollection<PostReaction> Reactions { get; set; } = new List<PostReaction>();
    public ICollection<PostConfirmation> Confirmations { get; set; } = new List<PostConfirmation>();
    public ICollection<ModerationReport> ModerationReports { get; set; } = new List<ModerationReport>();
}

public class PostImage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PostId { get; set; }
    public Post Post { get; set; } = null!;

    public string ImageUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public int OrderIndex { get; set; } = 0;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class PostReaction
{
    public long Id { get; set; }
    public Guid PostId { get; set; }
    public Post Post { get; set; } = null!;

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public ReactionType ReactionType { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class PostConfirmation
{
    public long Id { get; set; }
    public Guid PostId { get; set; }
    public Post Post { get; set; } = null!;

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public Point? UserCoordinates { get; set; }
    public bool IsNearby { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class ModerationReport
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PostId { get; set; }
    public Post Post { get; set; } = null!;

    public Guid ReporterUserId { get; set; }
    public User ReporterUser { get; set; } = null!;

    public ModerationReason Reason { get; set; }
    public string? Description { get; set; }
    public ModerationStatus Status { get; set; } = ModerationStatus.Pending;

    public Guid? ReviewedByUserId { get; set; }
    public string? ResolutionNotes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReviewedAt { get; set; }
}
