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
    public DbSet<PostReaction> PostReactions => Set<PostReaction>();
    public DbSet<PostConfirmation> PostConfirmations => Set<PostConfirmation>();
    public DbSet<ModerationReport> ModerationReports => Set<ModerationReport>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Enable PostGIS extension in EF Core model
        modelBuilder.HasPostgresExtension("postgis");
        modelBuilder.HasPostgresExtension("uuid-ossp");

        // User Configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);
            entity.HasIndex(u => u.Email).IsUnique();
            entity.HasIndex(u => u.Username).IsUnique();
            entity.Property(u => u.Username).HasMaxLength(50).IsRequired();
            entity.Property(u => u.Email).HasMaxLength(256).IsRequired();
            entity.Property(u => u.Province).HasMaxLength(100);
            entity.Property(u => u.Municipality).HasMaxLength(100);
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
            entity.Property(p => p.AddressReference).HasMaxLength(255);

            // Spatial Column: Geography Point with SRID 4326 (WGS84 GPS coords)
            entity.Property(p => p.LocationCoordinates)
                .HasColumnType("geography(Point, 4326)")
                .IsRequired();

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

            // One reaction per user per post per type
            entity.HasIndex(r => new { r.PostId, r.UserId, r.ReactionType }).IsUnique();

            entity.HasOne(r => r.Post)
                .WithMany(p => p.Reactions)
                .HasForeignKey(r => r.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(r => r.User)
                .WithMany(u => u.Reactions)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // PostConfirmation Configuration
        modelBuilder.Entity<PostConfirmation>(entity =>
        {
            entity.HasKey(c => c.Id);

            // Unique confirmation per user per post
            entity.HasIndex(c => new { c.PostId, c.UserId }).IsUnique();

            entity.Property(c => c.UserCoordinates)
                .HasColumnType("geography(Point, 4326)");

            entity.HasOne(c => c.Post)
                .WithMany(p => p.Confirmations)
                .HasForeignKey(c => c.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(c => c.User)
                .WithMany(u => u.Confirmations)
                .HasForeignKey(c => c.UserId)
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
