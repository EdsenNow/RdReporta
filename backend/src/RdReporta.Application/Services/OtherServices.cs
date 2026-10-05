using Microsoft.EntityFrameworkCore;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Application.Common.Models;
using RdReporta.Application.DTOs;
using RdReporta.Domain.Entities;
using RdReporta.Domain.Enums;

namespace RdReporta.Application.Services;

public interface ICategoryService
{
    Task<ApiResponse<List<CategoryDto>>> GetActiveCategoriesAsync(CancellationToken ct = default);
    Task<ApiResponse<CategoryDto>> CreateCategoryAsync(CreateCategoryRequest request, CancellationToken ct = default);
}

public class CategoryService : ICategoryService
{
    private readonly IApplicationDbContext _context;

    public CategoryService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ApiResponse<List<CategoryDto>>> GetActiveCategoriesAsync(CancellationToken ct = default)
    {
        var categories = await _context.Categories
            .Where(c => c.IsActive)
            .OrderBy(c => c.DisplayOrder)
            .ThenBy(c => c.Name)
            .Select(c => new CategoryDto(
                c.Id,
                c.Name,
                c.Slug,
                c.Description,
                c.IconName,
                c.ColorHex,
                c.DisplayOrder
            ))
            .ToListAsync(ct);

        return ApiResponse<List<CategoryDto>>.Ok(categories);
    }

    public async Task<ApiResponse<CategoryDto>> CreateCategoryAsync(CreateCategoryRequest request, CancellationToken ct = default)
    {
        var exists = await _context.Categories.AnyAsync(c => c.Slug.ToLower() == request.Slug.ToLower(), ct);
        if (exists)
        {
            return ApiResponse<CategoryDto>.Fail("Ya existe una categoría con ese slug.");
        }

        var category = new Category
        {
            Name = request.Name.Trim(),
            Slug = request.Slug.Trim().ToLowerInvariant(),
            Description = request.Description?.Trim(),
            IconName = request.IconName.Trim(),
            ColorHex = request.ColorHex.Trim(),
            DisplayOrder = request.DisplayOrder,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Categories.Add(category);
        await _context.SaveChangesAsync(ct);

        var dto = new CategoryDto(
            category.Id,
            category.Name,
            category.Slug,
            category.Description,
            category.IconName,
            category.ColorHex,
            category.DisplayOrder
        );

        return ApiResponse<CategoryDto>.Ok(dto, "Categoría creada exitosamente.");
    }
}

public interface IUserService
{
    Task<ApiResponse<UserProfileDto>> GetProfileAsync(Guid userId, CancellationToken ct = default);
    Task<ApiResponse<UserProfileDto>> UpdateProfileAsync(Guid userId, UpdateProfileRequest request, CancellationToken ct = default);
    Task<ApiResponse<bool>> DeleteAccountAsync(Guid userId, CancellationToken ct = default);
}

public class UserService : IUserService
{
    private readonly IApplicationDbContext _context;

    public UserService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ApiResponse<UserProfileDto>> GetProfileAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _context.Users
            .Include(u => u.Posts)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user == null)
        {
            return ApiResponse<UserProfileDto>.Fail("Usuario no encontrado.");
        }

        int totalPosts = user.Posts.Count(p => p.Status != PostStatus.Hidden);

        var dto = new UserProfileDto(
            user.Id,
            user.Username,
            string.IsNullOrWhiteSpace(user.DisplayName) ? user.Username : user.DisplayName,
            user.AvatarUrl,
            user.Province,
            user.Municipality,
            user.ReputationScore,
            user.ReputationLevel,
            totalPosts,
            user.CreatedAt,
            user.UsernameChangedAt?.AddDays(15),
            user.IsVerified,
            await _context.UserFollows.CountAsync(x => x.FollowedId == userId, ct),
            await _context.UserFollows.CountAsync(x => x.FollowerId == userId, ct),
            false
        );

        return ApiResponse<UserProfileDto>.Ok(dto);
    }

    public async Task<ApiResponse<UserProfileDto>> UpdateProfileAsync(Guid userId, UpdateProfileRequest request, CancellationToken ct = default)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user == null)
        {
            return ApiResponse<UserProfileDto>.Fail("Usuario no encontrado.");
        }

        if (!string.IsNullOrWhiteSpace(request.AvatarUrl))
        {
            var avatarUrl = request.AvatarUrl.Trim();
            if (!RdReporta.Application.Common.UploadReference.IsOwned(avatarUrl, userId,
                new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".jpg", ".jpeg", ".png", ".webp" }))
                return ApiResponse<UserProfileDto>.Fail("La foto de perfil debe ser una imagen subida por tu cuenta.");
            user.AvatarUrl = avatarUrl;
        }
        if (!string.IsNullOrWhiteSpace(request.DisplayName)) user.DisplayName = request.DisplayName.Trim();
        if (!string.IsNullOrWhiteSpace(request.Username))
        {
            var submittedUsername = request.Username.Trim();
            if (!System.Text.RegularExpressions.Regex.IsMatch(submittedUsername, "^[a-zA-Z0-9_]+$"))
                return ApiResponse<UserProfileDto>.Fail("El @usuario solo puede contener letras, números y guion bajo.");

            var username = submittedUsername.ToLowerInvariant();
            var sameUsernameIgnoringCase = string.Equals(
                username, user.Username, StringComparison.OrdinalIgnoreCase);
            if (!string.Equals(username, user.Username, StringComparison.Ordinal))
            {
                var nextChange = user.UsernameChangedAt?.AddDays(15);
                if (!sameUsernameIgnoringCase && nextChange.HasValue && nextChange.Value > DateTime.UtcNow)
                    return ApiResponse<UserProfileDto>.Fail($"Podrás cambiar tu @usuario nuevamente el {nextChange.Value:dd/MM/yyyy}.");

                var normalized = username.ToLowerInvariant();
                if (await _context.Users.AnyAsync(u => u.Id != userId && u.Username.ToLower() == normalized, ct))
                    return ApiResponse<UserProfileDto>.Fail("Ese @usuario ya está en uso.");

                user.Username = username;
                if (!sameUsernameIgnoringCase)
                    user.UsernameChangedAt = DateTime.UtcNow;
            }
        }
        if (!string.IsNullOrWhiteSpace(request.Province)) user.Province = request.Province.Trim();
        if (!string.IsNullOrWhiteSpace(request.Municipality)) user.Municipality = request.Municipality.Trim();
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(ct);
        return await GetProfileAsync(userId, ct);
    }

    public async Task<ApiResponse<bool>> DeleteAccountAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _context.Users
            .Include(u => u.Posts)
                .ThenInclude(p => p.Images)
            .Include(u => u.Posts)
                .ThenInclude(p => p.Reactions)
            .Include(u => u.Posts)
                .ThenInclude(p => p.ModerationReports)
            .Include(u => u.Reactions)
            .Include(u => u.ReportsSubmitted)
            .Include(u => u.UserRoles)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user == null)
        {
            return ApiResponse<bool>.Fail("Usuario no encontrado.");
        }

        // 1. Delete all the user's posts and their children (images, reactions, moderation reports)
        foreach (var post in user.Posts.ToList())
        {
            _context.PostImages.RemoveRange(post.Images);
            _context.PostReactions.RemoveRange(post.Reactions);
            _context.ModerationReports.RemoveRange(post.ModerationReports);
            _context.Posts.Remove(post);
        }

        // 2. Delete the user's reactions on OTHER people's posts
        _context.PostReactions.RemoveRange(user.Reactions);

        // 3. Delete moderation reports submitted by this user (on other posts)
        _context.ModerationReports.RemoveRange(user.ReportsSubmitted);

        // 4. Delete follows (both directions)
        var follows = await _context.UserFollows
            .Where(f => f.FollowerId == userId || f.FollowedId == userId)
            .ToListAsync(ct);
        _context.UserFollows.RemoveRange(follows);

        // 5. Delete notifications (received and sent as actor)
        await _context.UserNotifications
            .Where(n => n.UserId == userId || n.ActorUserId == userId)
            .ExecuteDeleteAsync(ct);

        // 6. Delete device registrations
        await _context.DeviceRegistrations
            .Where(d => d.UserId == userId)
            .ExecuteDeleteAsync(ct);

        // 7. Delete user roles
        _context.UserRoles.RemoveRange(user.UserRoles);

        // 8. Finally remove the user
        _context.Users.Remove(user);

        await _context.SaveChangesAsync(ct);
        return ApiResponse<bool>.Ok(true, "Tu cuenta ha sido eliminada permanentemente.");
    }
}

public interface IModerationService
{
    Task<ApiResponse<bool>> ReportPostAsync(CreateModerationReportRequest request, Guid reporterUserId, CancellationToken ct = default);
    Task<ApiResponse<PagedResult<ModerationReportDto>>> GetPendingReportsAsync(int pageNumber, int pageSize, CancellationToken ct = default);
    Task<ApiResponse<bool>> ResolveReportAsync(Guid reportId, ResolveModerationRequest request, Guid moderatorUserId, CancellationToken ct = default);
}

public class ModerationService : IModerationService
{
    private readonly IApplicationDbContext _context;

    public ModerationService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ApiResponse<bool>> ReportPostAsync(CreateModerationReportRequest request, Guid reporterUserId, CancellationToken ct = default)
    {
        var post = await _context.Posts.FirstOrDefaultAsync(p => p.Id == request.PostId, ct);
        if (post == null)
        {
            return ApiResponse<bool>.Fail("Publicación no encontrada.");
        }

        var alreadyReported = await _context.ModerationReports
            .AnyAsync(r => r.PostId == request.PostId && r.ReporterUserId == reporterUserId, ct);

        if (alreadyReported)
        {
            return ApiResponse<bool>.Fail("Ya has enviado una denuncia para esta publicación.");
        }

        var report = new ModerationReport
        {
            Id = Guid.NewGuid(),
            PostId = request.PostId,
            ReporterUserId = reporterUserId,
            Reason = request.Reason,
            Description = request.Description?.Trim(),
            Status = ModerationStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        _context.ModerationReports.Add(report);
        await _context.SaveChangesAsync(ct);

        return ApiResponse<bool>.Ok(true, "Reporte enviado a moderación. Gracias por ayudar a la comunidad.");
    }

    public async Task<ApiResponse<PagedResult<ModerationReportDto>>> GetPendingReportsAsync(int pageNumber, int pageSize, CancellationToken ct = default)
    {
        pageNumber = Math.Max(1, pageNumber);
        pageSize = Math.Clamp(pageSize, 1, 100);
        var query = _context.ModerationReports
            .Include(r => r.Post)
            .Include(r => r.ReporterUser)
            .Where(r => r.Status == ModerationStatus.Pending);

        var total = await query.CountAsync(ct);
        var items = await query
            .OrderByDescending(r => r.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var dtos = items.Select(r => new ModerationReportDto(
            r.Id,
            r.PostId,
            r.Post.Title,
            r.ReporterUserId,
            r.ReporterUser.Username,
            r.Reason,
            r.Description,
            r.Status,
            r.CreatedAt,
            r.ResolutionNotes
        )).ToList();

        var result = new PagedResult<ModerationReportDto>
        {
            Items = dtos,
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalCount = total
        };

        return ApiResponse<PagedResult<ModerationReportDto>>.Ok(result);
    }

    public async Task<ApiResponse<bool>> ResolveReportAsync(Guid reportId, ResolveModerationRequest request, Guid moderatorUserId, CancellationToken ct = default)
    {
        var report = await _context.ModerationReports
            .Include(r => r.Post)
                .ThenInclude(p => p.User)
            .FirstOrDefaultAsync(r => r.Id == reportId, ct);

        if (report == null)
        {
            return ApiResponse<bool>.Fail("Reporte de moderación no encontrado.");
        }

        if (report.Status != ModerationStatus.Pending)
            return ApiResponse<bool>.Fail("Esta denuncia ya fue resuelta.");
        if (request.Status == ModerationStatus.Pending || !Enum.IsDefined(request.Status)
            || (request.HidePost && request.Status != ModerationStatus.ActionTaken))
            return ApiResponse<bool>.Fail("La resolución seleccionada no es válida.");
        report.Status = request.Status;
        report.ResolutionNotes = request.ResolutionNotes?.Trim();
        report.ReviewedByUserId = moderatorUserId;
        report.ReviewedAt = DateTime.UtcNow;

        if (request.HidePost && report.Post != null && report.Post.Status != PostStatus.Hidden)
        {
            report.Post.Status = PostStatus.Hidden;
            report.Post.UpdatedAt = DateTime.UtcNow;

            // Penalty to author
            report.Post.User.ReputationScore = Math.Max(0, report.Post.User.ReputationScore - 20);
        }

        await _context.SaveChangesAsync(ct);
        return ApiResponse<bool>.Ok(true, "Reporte resuelto.");
    }
}
