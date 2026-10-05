using Microsoft.EntityFrameworkCore;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Domain.Entities;

namespace RdReporta.Infrastructure.Persistence;

public class ApplicationDbContext : DbContext, IApplicationDbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Post> Posts => Set<Post>();
    public DbSet<PostImage> PostImages => Set<PostImage>();
    public DbSet<PostView> PostViews => Set<PostView>();

    public async Task RecordUniquePostViewAsync(Guid postId, Guid userId, CancellationToken ct = default)
    {
        // One statement: duplicate requests cannot increment, and a failed
        // increment cannot leave a recorded view without its counter.
        await Database.ExecuteSqlInterpolatedAsync($"""
            WITH inserted AS (
                INSERT INTO "PostViews" ("PostId", "UserId", "ViewedAt")
                SELECT "Id", {userId}, CURRENT_TIMESTAMP FROM "Posts"
                WHERE "Id" = {postId} AND "Status" <> {(int)RdReporta.Domain.Enums.PostStatus.Hidden}
                ON CONFLICT ("PostId", "UserId") DO NOTHING
                RETURNING "PostId"
            )
            UPDATE "Posts" SET "ViewsCount" = "ViewsCount" + 1
            WHERE "Id" IN (SELECT "PostId" FROM inserted)
            """, ct);
    }
    public DbSet<PostReaction> PostReactions => Set<PostReaction>();
    public DbSet<ModerationReport> ModerationReports => Set<ModerationReport>();
    public DbSet<UserFollow> UserFollows => Set<UserFollow>();
    public DbSet<UserNotification> UserNotifications => Set<UserNotification>();
    public DbSet<DeviceRegistration> DeviceRegistrations => Set<DeviceRegistration>();
    public DbSet<PushDelivery> PushDeliveries => Set<PushDelivery>();

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var notifications = ChangeTracker.Entries<UserNotification>()
            .Where(x => x.State == EntityState.Added).Select(x => x.Entity).ToList();
        if (notifications.Count > 0)
        {
            var userIds = notifications.Select(x => x.UserId).Distinct().ToList();
            var devices = await DeviceRegistrations.AsNoTracking()
                .Where(x => userIds.Contains(x.UserId)).ToListAsync(cancellationToken);
            var queued = ChangeTracker.Entries<PushDelivery>()
                .Select(x => (x.Entity.NotificationId, x.Entity.DeviceRegistrationId)).ToHashSet();
            foreach (var notification in notifications)
                foreach (var device in devices.Where(x => x.UserId == notification.UserId))
                    if (queued.Add((notification.Id, device.Id)))
                        PushDeliveries.Add(new PushDelivery
                        {
                            NotificationId = notification.Id,
                            DeviceRegistrationId = device.Id
                        });
        }
        // The inbox and its pending deliveries commit together.
        return await base.SaveChangesAsync(cancellationToken);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<PushDelivery>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.NotificationId, x.DeviceRegistrationId }).IsUnique();
            entity.HasIndex(x => x.NextAttemptAt).HasFilter("\"CompletedAt\" IS NULL");
            entity.HasOne(x => x.Notification).WithMany().HasForeignKey(x => x.NotificationId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.DeviceRegistration).WithMany().HasForeignKey(x => x.DeviceRegistrationId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<PostView>(entity => {
            entity.HasKey(pv => new { pv.PostId, pv.UserId });
            entity.HasOne(pv => pv.Post).WithMany().HasForeignKey(pv => pv.PostId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(pv => pv.User).WithMany().HasForeignKey(pv => pv.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // Enable PostGIS extension in EF Core model
        modelBuilder.HasPostgresExtension("postgis");
        modelBuilder.HasPostgresExtension("uuid-ossp");

        // User Configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);
            entity.HasIndex(u => u.Email).IsUnique();
            // Case-insensitive uniqueness is created as a PostgreSQL expression
            // index in DbInitializer. EF Core model indexes only support property access.
            entity.Property(u => u.Username).HasMaxLength(50).IsRequired();
            entity.Property(u => u.DisplayName).HasMaxLength(80).IsRequired();
            entity.Property(u => u.Email).HasMaxLength(256).IsRequired();
            entity.Property(u => u.Province).HasMaxLength(100);
            entity.Property(u => u.Municipality).HasMaxLength(100);
        });

        modelBuilder.Entity<UserFollow>(entity =>
        {
            entity.HasKey(x => new { x.FollowerId, x.FollowedId });
            entity.HasOne(x => x.Follower).WithMany().HasForeignKey(x => x.FollowerId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Followed).WithMany().HasForeignKey(x => x.FollowedId).OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => x.FollowedId);
        });

        modelBuilder.Entity<UserNotification>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Type).HasMaxLength(30).IsRequired();
            entity.Property(x => x.Message).HasMaxLength(300).IsRequired();
            entity.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => new { x.UserId, x.IsRead, x.CreatedAt });
        });
        modelBuilder.Entity<DeviceRegistration>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Token).HasMaxLength(500).IsRequired();
            entity.Property(x => x.Platform).HasMaxLength(20).IsRequired();
            entity.HasIndex(x => x.Token).IsUnique();
            entity.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // Role & UserRole Configuration
        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(r => r.Id);
            entity.Property(r => r.Name).HasMaxLength(50).IsRequired();
            entity.HasIndex(r => r.Name).IsUnique();
        });

        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.HasKey(ur => new { ur.UserId, ur.RoleId });

            entity.HasOne(ur => ur.User)
                .WithMany(u => u.UserRoles)
                .HasForeignKey(ur => ur.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(ur => ur.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(ur => ur.RoleId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Category Configuration
        modelBuilder.Entity<Category>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.Property(c => c.Name).HasMaxLength(50).IsRequired();
            entity.Property(c => c.Slug).HasMaxLength(60).IsRequired();
            entity.HasIndex(c => c.Slug).IsUnique();
            entity.Property(c => c.IconName).HasMaxLength(50);
            entity.Property(c => c.ColorHex).HasMaxLength(10);
        });

        // Post Configuration with PostGIS
        modelBuilder.Entity<Post>(entity =>
        {
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Title).HasMaxLength(150).IsRequired();
            entity.Property(p => p.Description).IsRequired();
            entity.Property(p => p.Province).HasMaxLength(100).IsRequired();
            entity.Property(p => p.Municipality).HasMaxLength(100).IsRequired();
            entity.Property(p => p.Neighborhood).HasMaxLength(100);
            entity.Property(p => p.AddressReference).HasMaxLength(255);
            entity.Property(p => p.VideoUrl).HasMaxLength(1000);

            // Spatial Column: Geography Point with SRID 4326 (WGS84 GPS coords)
            entity.Property(p => p.LocationCoordinates)
                .HasColumnType("geography(Point, 4326)");

            // Spatial GIST index for fast radius/distance queries
            entity.HasIndex(p => p.LocationCoordinates)
                .HasMethod("GIST");

            entity.HasIndex(p => p.CreatedAt);
            entity.HasIndex(p => p.Province);

            entity.HasOne(p => p.User)
                .WithMany(u => u.Posts)
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(p => p.Category)
                .WithMany(c => c.Posts)
                .HasForeignKey(p => p.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // PostImage Configuration
        modelBuilder.Entity<PostImage>(entity =>
        {
            entity.HasKey(i => i.Id);
            entity.Property(i => i.ImageUrl).HasMaxLength(1000).IsRequired();
            entity.Property(i => i.ThumbnailUrl).HasMaxLength(1000);

            entity.HasOne(i => i.Post)
                .WithMany(p => p.Images)
                .HasForeignKey(i => i.PostId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // PostReaction Configuration
        modelBuilder.Entity<PostReaction>(entity =>
        {
            entity.HasKey(r => r.Id);

            // A user can keep only one current reaction on each post.
            entity.HasIndex(r => new { r.PostId, r.UserId }).IsUnique();

            entity.HasOne(r => r.Post)
                .WithMany(p => p.Reactions)
                .HasForeignKey(r => r.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(r => r.User)
                .WithMany(u => u.Reactions)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // ModerationReport Configuration
        modelBuilder.Entity<ModerationReport>(entity =>
        {
            entity.HasKey(m => m.Id);

            // Unique report per user per post
            entity.HasIndex(m => new { m.PostId, m.ReporterUserId }).IsUnique();

            entity.HasOne(m => m.Post)
                .WithMany(p => p.ModerationReports)
                .HasForeignKey(m => m.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(m => m.ReporterUser)
                .WithMany(u => u.ReportsSubmitted)
                .HasForeignKey(m => m.ReporterUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
