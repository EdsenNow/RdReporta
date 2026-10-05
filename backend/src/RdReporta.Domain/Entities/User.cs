using RdReporta.Domain.Enums;

namespace RdReporta.Domain.Entities;

public class User : BaseEntity<Guid>
{
    public string Username { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public DateTime? UsernameChangedAt { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? PasswordHash { get; set; }
    public string? AvatarUrl { get; set; }
    public string? Province { get; set; }
    public string? Municipality { get; set; }
    public int ReputationScore { get; set; } = 100;
    public ReputationLevel ReputationLevel { get; set; } = ReputationLevel.Ciudadano;
    public bool IsActive { get; set; } = true;
    public bool IsVerified { get; set; } = false;
    public string? RefreshToken { get; set; }
    public DateTime? RefreshTokenExpiryTime { get; set; }
    public string? PasswordResetCode { get; set; }
    public DateTime? PasswordResetExpiresAt { get; set; }

    // Navigation collections
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
    public ICollection<Post> Posts { get; set; } = new List<Post>();
    public ICollection<PostReaction> Reactions { get; set; } = new List<PostReaction>();
    public ICollection<ModerationReport> ReportsSubmitted { get; set; } = new List<ModerationReport>();
}

public class Role
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty; // "Ciudadano", "Moderador", "Administrador", "Institucion"
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}

public class UserRole
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public int RoleId { get; set; }
    public Role Role { get; set; } = null!;
}
