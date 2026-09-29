using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Application.Common.Models;
using RdReporta.Application.DTOs;
using RdReporta.Domain.Entities;
using RdReporta.Domain.Enums;

namespace RdReporta.Application.Services;

public interface IPostService
{
    Task<ApiResponse<PostDto>> CreatePostAsync(CreatePostRequest request, Guid currentUserId, CancellationToken ct = default);
    Task<ApiResponse<PostDto>> GetByIdAsync(Guid id, Guid? currentUserId, CancellationToken ct = default);
    Task<ApiResponse<PagedResult<PostDto>>> GetRecentAsync(int pageNumber, int pageSize, int? categoryId, Guid? currentUserId, CancellationToken ct = default);
    Task<ApiResponse<PagedResult<PostDto>>> GetNearbyAsync(NearbyPostsRequest request, Guid? currentUserId, CancellationToken ct = default);
    Task<ApiResponse<PagedResult<PostDto>>> GetPopularThisWeekAsync(int pageNumber, int pageSize, Guid? currentUserId, CancellationToken ct = default);
    Task<ApiResponse<List<PostMapPinDto>>> GetMapPinsAsync(double minLat, double maxLat, double minLng, double maxLng, int? categoryId, CancellationToken ct = default);
    Task<ApiResponse<bool>> ToggleReactionAsync(Guid postId, ReactionType reactionType, Guid currentUserId, CancellationToken ct = default);
    Task<ApiResponse<bool>> ConfirmPostAsync(Guid postId, PostConfirmationRequest request, Guid currentUserId, CancellationToken ct = default);
}

public class PostService : IPostService
{
    private readonly IApplicationDbContext _context;
    private readonly GeometryFactory _geometryFactory = new(new PrecisionModel(), 4326);

    public PostService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ApiResponse<PostDto>> CreatePostAsync(CreatePostRequest request, Guid currentUserId, CancellationToken ct = default)
    {
        var category = await _context.Categories.FirstOrDefaultAsync(c => c.Id == request.CategoryId && c.IsActive, ct);
        if (category == null)
        {
            return ApiResponse<PostDto>.Fail("La categoría seleccionada no existe o no está activa.");
        }

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == currentUserId, ct);
        if (user == null || !user.IsActive)
        {
            return ApiResponse<PostDto>.Fail("Usuario inválido o inactivo.");
        }

        // PostGIS point: Longitude (X), Latitude (Y)
        var coordinate = _geometryFactory.CreatePoint(new Coordinate(request.Longitude, request.Latitude));

        var post = new Post
        {
            Id = Guid.NewGuid(),
            UserId = currentUserId,
            CategoryId = request.CategoryId,
            Title = request.Title.Trim(),
            Description = request.Description.Trim(),
            LocationCoordinates = coordinate,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            Province = request.Province.Trim(),
            Municipality = request.Municipality.Trim(),
            Neighborhood = request.Neighborhood?.Trim(),
            AddressReference = request.AddressReference?.Trim(),
            Status = PostStatus.Active,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        if (request.ImageUrls != null && request.ImageUrls.Count > 0)
        {
            int index = 0;
            foreach (var url in request.ImageUrls.Take(4))
            {
                post.Images.Add(new PostImage
                {
                    Id = Guid.NewGuid(),
                    PostId = post.Id,
                    ImageUrl = url,
                    OrderIndex = index++,
                    CreatedAt = DateTime.UtcNow
                });
            }
        }

        _context.Posts.Add(post);

        var followerIds = await _context.UserFollows
            .Where(x => x.FollowedId == currentUserId)
            .Select(x => x.FollowerId).ToListAsync(ct);
        foreach (var followerId in followerIds)
            _context.UserNotifications.Add(new UserNotification
            {
                UserId = followerId,
                ActorUserId = currentUserId,
                PostId = post.Id,
                Type = "NewPost",
                Message = $"{(string.IsNullOrWhiteSpace(user.DisplayName) ? user.Username : user.DisplayName)} publicó una nueva incidencia."
            });

        // Increase reputation points slightly for posting
        user.ReputationScore += 2;
        UpdateReputationLevel(user);
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(ct);

        var dto = MapToDto(post, user, category, currentUserId);
        return ApiResponse<PostDto>.Ok(dto, "Publicación creada exitosamente.");
    }

    public async Task<ApiResponse<PostDto>> GetByIdAsync(Guid id, Guid? currentUserId, CancellationToken ct = default)
    {
        var post = await _context.Posts
            .Include(p => p.User)
            .Include(p => p.Category)
            .Include(p => p.Images)
            .Include(p => p.Reactions)
            .Include(p => p.Confirmations)
            .FirstOrDefaultAsync(p => p.Id == id && p.Status != PostStatus.Hidden, ct);

        if (post == null)
        {
            return ApiResponse<PostDto>.Fail("Publicación no encontrada.");
        }

        // Increment view count
        post.ViewsCount++;
        await _context.SaveChangesAsync(ct);

        var dto = MapToDto(post, post.User, post.Category, currentUserId);
        return ApiResponse<PostDto>.Ok(dto);
    }

    public async Task<ApiResponse<PagedResult<PostDto>>> GetRecentAsync(
        int pageNumber,
        int pageSize,
        int? categoryId,
        Guid? currentUserId,
        CancellationToken ct = default)
    {
        pageNumber = Math.Max(1, pageNumber);
        pageSize = Math.Clamp(pageSize, 1, 100);
        var query = _context.Posts
            .Include(p => p.User)
            .Include(p => p.Category)
            .Include(p => p.Images)
            .Include(p => p.Reactions)
            .Include(p => p.Confirmations)
            .Where(p => p.Status == PostStatus.Active);

        if (categoryId.HasValue)
        {
            query = query.Where(p => p.CategoryId == categoryId.Value);
        }

        var total = await query.CountAsync(ct);
        var items = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var dtos = items.Select(p => MapToDto(p, p.User, p.Category, currentUserId)).ToList();

        var result = new PagedResult<PostDto>
        {
            Items = dtos,
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalCount = total
        };

        return ApiResponse<PagedResult<PostDto>>.Ok(result);
    }

    public async Task<ApiResponse<PagedResult<PostDto>>> GetNearbyAsync(
        NearbyPostsRequest request,
        Guid? currentUserId,
        CancellationToken ct = default)
    {
        var userPoint = _geometryFactory.CreatePoint(new Coordinate(request.Longitude, request.Latitude));
        double radiusInMeters = request.RadiusKm * 1000.0;

        // PostGIS distance evaluation
        var query = _context.Posts
            .Include(p => p.User)
            .Include(p => p.Category)
            .Include(p => p.Images)
            .Include(p => p.Reactions)
            .Include(p => p.Confirmations)
            .Where(p => p.Status == PostStatus.Active && p.LocationCoordinates.IsWithinDistance(userPoint, radiusInMeters));

        if (request.CategoryId.HasValue)
        {
            query = query.Where(p => p.CategoryId == request.CategoryId.Value);
        }

        var total = await query.CountAsync(ct);
        var items = await query
            .OrderBy(p => p.LocationCoordinates.Distance(userPoint))
            .Skip((request.PageNumber - 1) * request.PageSize)
            .Take(request.PageSize)
            .ToListAsync(ct);

        var dtos = items.Select(p =>
        {
            var dto = MapToDto(p, p.User, p.Category, currentUserId);
            // Distance in meters
            dto = dto with { DistanceInMeters = DistanceMeters(request.Latitude, request.Longitude, p.Latitude, p.Longitude) };
            return dto;
        }).ToList();

        var result = new PagedResult<PostDto>
        {
            Items = dtos,
            PageNumber = request.PageNumber,
            PageSize = request.PageSize,
            TotalCount = total
        };

        return ApiResponse<PagedResult<PostDto>>.Ok(result);
    }

    public async Task<ApiResponse<PagedResult<PostDto>>> GetPopularThisWeekAsync(
        int pageNumber,
        int pageSize,
        Guid? currentUserId,
        CancellationToken ct = default)
    {
        pageNumber = Math.Max(1, pageNumber);
        pageSize = Math.Clamp(pageSize, 1, 100);
        var sevenDaysAgo = DateTime.UtcNow.AddDays(-7);

        var query = _context.Posts
            .Include(p => p.User)
            .Include(p => p.Category)
            .Include(p => p.Images)
            .Include(p => p.Reactions)
            .Include(p => p.Confirmations)
            .Where(p => p.Status == PostStatus.Active && p.CreatedAt >= sevenDaysAgo);

        var total = await query.CountAsync(ct);

        // Weighted algorithm: Confirmations * 4 + Reactions * 2 + Views * 0.1
        var items = await query
            .OrderByDescending(p => (p.ConfirmationsCount * 4) + (p.ReactionsCount * 2) + (p.ViewsCount * 0.1))
            .ThenByDescending(p => p.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var dtos = items.Select(p => MapToDto(p, p.User, p.Category, currentUserId)).ToList();

        var result = new PagedResult<PostDto>
        {
            Items = dtos,
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalCount = total
        };

        return ApiResponse<PagedResult<PostDto>>.Ok(result);
    }

    public async Task<ApiResponse<List<PostMapPinDto>>> GetMapPinsAsync(
        double minLat,
        double maxLat,
        double minLng,
        double maxLng,
        int? categoryId,
        CancellationToken ct = default)
    {
        var query = _context.Posts
            .Include(p => p.Category)
            .Include(p => p.Images)
            .Where(p => p.Status == PostStatus.Active
                     && p.Latitude >= minLat && p.Latitude <= maxLat
                     && p.Longitude >= minLng && p.Longitude <= maxLng);

        if (categoryId.HasValue)
        {
            query = query.Where(p => p.CategoryId == categoryId.Value);
        }

        var pins = await query
            .OrderByDescending(p => p.CreatedAt)
            .Take(200)
            .Select(p => new PostMapPinDto(
                p.Id,
                p.Latitude,
                p.Longitude,
                p.CategoryId,
                p.Category.Name,
                p.Category.ColorHex,
                p.Title,
                p.Images.OrderBy(i => i.OrderIndex).Select(i => i.ImageUrl).FirstOrDefault(),
                p.ConfirmationsCount,
                p.CreatedAt
            ))
            .ToListAsync(ct);

        return ApiResponse<List<PostMapPinDto>>.Ok(pins);
    }

    public async Task<ApiResponse<bool>> ToggleReactionAsync(
        Guid postId,
        ReactionType reactionType,
        Guid currentUserId,
        CancellationToken ct = default)
    {
        var post = await _context.Posts
            .Include(p => p.Reactions)
            .FirstOrDefaultAsync(p => p.Id == postId && p.Status == PostStatus.Active, ct);

        if (post == null)
        {
            return ApiResponse<bool>.Fail("Publicación no encontrada.");
        }

        var existing = post.Reactions.FirstOrDefault(r => r.UserId == currentUserId);
        if (existing != null)
        {
            if (existing.ReactionType == reactionType)
            {
                // Remove reaction (toggle off)
                _context.PostReactions.Remove(existing);
                post.ReactionsCount = Math.Max(0, post.ReactionsCount - 1);
                await _context.SaveChangesAsync(ct);
                return ApiResponse<bool>.Ok(false, "Reacción eliminada.");
            }
            else
            {
                // Switch reaction type
                existing.ReactionType = reactionType;
                existing.CreatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync(ct);
                return ApiResponse<bool>.Ok(true, "Reacción actualizada.");
            }
        }

        var newReaction = new PostReaction
        {
            PostId = postId,
            UserId = currentUserId,
            ReactionType = reactionType,
            CreatedAt = DateTime.UtcNow
        };

        _context.PostReactions.Add(newReaction);
        post.ReactionsCount++;
        await _context.SaveChangesAsync(ct);

        return ApiResponse<bool>.Ok(true, "Reacción agregada.");
    }

    public async Task<ApiResponse<bool>> ConfirmPostAsync(
        Guid postId,
        PostConfirmationRequest request,
        Guid currentUserId,
        CancellationToken ct = default)
    {
        var post = await _context.Posts
            .Include(p => p.User)
            .Include(p => p.Confirmations)
            .FirstOrDefaultAsync(p => p.Id == postId && p.Status == PostStatus.Active, ct);

        if (post == null)
        {
            return ApiResponse<bool>.Fail("Publicación no encontrada.");
        }

        if (post.UserId == currentUserId)
        {
            return ApiResponse<bool>.Fail("No puedes confirmar tu propia publicación.");
        }

        var existing = post.Confirmations.FirstOrDefault(c => c.UserId == currentUserId);
        if (existing != null)
        {
            // Toggle off confirmation
            _context.PostConfirmations.Remove(existing);
            post.ConfirmationsCount = Math.Max(0, post.ConfirmationsCount - 1);
            post.User.ReputationScore = Math.Max(0, post.User.ReputationScore - 5);
            UpdateReputationLevel(post.User);
            await _context.SaveChangesAsync(ct);
            return ApiResponse<bool>.Ok(false, "Confirmación retirada.");
        }

        Point? userCoords = null;
        bool isNearby = false;

        if (request.Latitude.HasValue && request.Longitude.HasValue)
        {
            userCoords = _geometryFactory.CreatePoint(new Coordinate(request.Longitude.Value, request.Latitude.Value));
            // Check if within 500 meters
            isNearby = DistanceMeters(request.Latitude.Value, request.Longitude.Value, post.Latitude, post.Longitude) <= 500;
        }

        var confirmation = new PostConfirmation
        {
            PostId = postId,
            UserId = currentUserId,
            UserCoordinates = null, // Only retain the proximity result, not a citizen's location.
            IsNearby = isNearby,
            CreatedAt = DateTime.UtcNow
        };

        _context.PostConfirmations.Add(confirmation);
        post.ConfirmationsCount++;

        // Increase author reputation for verified reports
        post.User.ReputationScore += 5;
        UpdateReputationLevel(post.User);

        await _context.SaveChangesAsync(ct);
        return ApiResponse<bool>.Ok(true, "Publicación confirmada exitosamente.");
    }

    public static double DistanceMeters(double lat1, double lng1, double lat2, double lng2)
    {
        const double radians = Math.PI / 180;
        var a = Math.Pow(Math.Sin((lat2 - lat1) * radians / 2), 2)
            + Math.Cos(lat1 * radians) * Math.Cos(lat2 * radians)
            * Math.Pow(Math.Sin((lng2 - lng1) * radians / 2), 2);
        return 6371000 * 2 * Math.Asin(Math.Sqrt(Math.Clamp(a, 0, 1)));
    }

    private static void UpdateReputationLevel(User user)
    {
        if (user.ReputationScore >= 300)
            user.ReputationLevel = ReputationLevel.ColaboradorConfiable;
        else if (user.ReputationScore >= 150)
            user.ReputationLevel = ReputationLevel.Colaborador;
        else
            user.ReputationLevel = ReputationLevel.Ciudadano;
    }

    public static PostDto MapToDto(Post post, User user, Category category, Guid? currentUserId)
    {
        bool hasConfirmed = currentUserId.HasValue && post.Confirmations.Any(c => c.UserId == currentUserId.Value);
        ReactionType? userReaction = currentUserId.HasValue
            ? post.Reactions.FirstOrDefault(r => r.UserId == currentUserId.Value)?.ReactionType
            : null;

        return new PostDto(
            post.Id,
            user.Id,
            user.Username,
            user.AvatarUrl,
            user.ReputationLevel,
            category.Id,
            category.Name,
            category.IconName,
            category.ColorHex,
            post.Title,
            post.Description,
            post.Latitude,
            post.Longitude,
            post.Province,
            post.Municipality,
            post.Neighborhood,
            post.AddressReference,
            post.Status,
            post.ViewsCount,
            post.ReactionsCount,
            post.ConfirmationsCount,
            post.Images.OrderBy(i => i.OrderIndex).Select(i => i.ImageUrl).ToList(),
            post.CreatedAt,
            null,
            hasConfirmed,
            userReaction
        );
    }
}
