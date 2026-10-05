using Microsoft.EntityFrameworkCore;
using RdReporta.Domain.Entities;

namespace RdReporta.Application.Common.Interfaces;

public interface IApplicationDbContext
{
    DbSet<User> Users { get; }
    DbSet<Role> Roles { get; }
    DbSet<UserRole> UserRoles { get; }
    DbSet<Category> Categories { get; }
    DbSet<Post> Posts { get; }
    DbSet<PostImage> PostImages { get; }
    DbSet<PostView> PostViews { get; }
    DbSet<PostReaction> PostReactions { get; }
    DbSet<ModerationReport> ModerationReports { get; }
    DbSet<UserFollow> UserFollows { get; }
    DbSet<UserNotification> UserNotifications { get; }
    DbSet<DeviceRegistration> DeviceRegistrations { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task RecordUniquePostViewAsync(Guid postId, Guid userId, CancellationToken ct = default);
}
