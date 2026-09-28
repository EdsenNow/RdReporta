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
    DbSet<PostReaction> PostReactions { get; }
    DbSet<PostConfirmation> PostConfirmations { get; }
    DbSet<ModerationReport> ModerationReports { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
