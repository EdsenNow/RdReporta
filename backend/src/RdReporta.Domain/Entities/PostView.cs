namespace RdReporta.Domain.Entities;

public class PostView
{
    public Guid PostId { get; set; }
    public Post Post { get; set; } = null!;

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public DateTime ViewedAt { get; set; } = DateTime.UtcNow;
}
