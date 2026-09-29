using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Application.Common.Models;
using RdReporta.Application.DTOs;
using RdReporta.Domain.Enums;

namespace RdReporta.Api.Controllers;

[ApiController]
[Route("api/management")]
[Authorize(Roles = "Moderador,Administrador")]
public class ManagementController(IApplicationDbContext db) : ControllerBase
{
    [HttpGet("stats")]
    public async Task<IActionResult> Stats(CancellationToken ct) => Ok(new
    {
        success = true,
        data = new
        {
            totalPosts = await db.Posts.CountAsync(ct),
            activePosts = await db.Posts.CountAsync(p => p.Status == PostStatus.Active, ct),
            resolvedPosts = await db.Posts.CountAsync(p => p.Status == PostStatus.Resolved, ct),
            totalConfirmations = await db.PostConfirmations.CountAsync(ct),
            totalReactions = await db.PostReactions.CountAsync(ct),
            pendingReports = await db.ModerationReports.CountAsync(r => r.Status == ModerationStatus.Pending, ct)
        }
    });

    [HttpGet("posts")]
    public async Task<IActionResult> Posts([FromQuery, Range(1, int.MaxValue)] int page = 1,
        [FromQuery, Range(1, 100)] int pageSize = 20, [FromQuery] PostStatus? status = null,
        [FromQuery] int? categoryId = null, [FromQuery, MaxLength(150)] string? search = null,
        CancellationToken ct = default)
    {
        var query = db.Posts.AsNoTracking().AsQueryable();
        if (status.HasValue) query = query.Where(p => p.Status == status);
        if (categoryId.HasValue) query = query.Where(p => p.CategoryId == categoryId);
        if (!string.IsNullOrWhiteSpace(search)) query = query.Where(p => p.Title.Contains(search) || p.Description.Contains(search));
        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(p => p.CreatedAt).ThenBy(p => p.Id)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .Select(p => new { p.Id, p.UserId, AuthorUsername = p.User.Username, p.CategoryId,
                CategoryName = p.Category.Name, CategoryColor = p.Category.ColorHex, p.Title,
                p.Description, p.Latitude, p.Longitude, p.Province, p.Municipality, p.Status,
                p.ViewsCount, p.ReactionsCount, p.ConfirmationsCount, p.CreatedAt,
                Images = p.Images.OrderBy(i => i.OrderIndex).Select(i => i.ImageUrl).ToList() })
            .ToListAsync(ct);
        return Ok(new { success = true, data = new { items, totalCount, pageNumber = page, pageSize } });
    }

    [HttpGet("users")]
    [Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Users(
        [FromQuery, Range(1, int.MaxValue)] int page = 1,
        [FromQuery, Range(1, 100)] int pageSize = 20,
        [FromQuery, MaxLength(100)] string? search = null,
        CancellationToken ct = default)
    {
        var query = db.Users.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(u => u.Username.ToLower().Contains(term)
                || u.DisplayName.ToLower().Contains(term)
                || u.Email.ToLower().Contains(term));
        }

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderByDescending(u => u.IsVerified)
            .ThenBy(u => u.DisplayName).ThenBy(u => u.Id)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .Select(u => new
            {
                u.Id,
                u.DisplayName,
                u.Username,
                u.Email,
                u.AvatarUrl,
                u.IsVerified,
                u.IsActive,
                u.CreatedAt
            })
            .ToListAsync(ct);

        return Ok(new { success = true, data = new { items, totalCount, pageNumber = page, pageSize } });
    }

    [HttpPatch("users/{id:guid}/verification")]
    [Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Verification(Guid id, UpdateVerificationRequest request, CancellationToken ct)
    {
        var user = await db.Users.FindAsync([id], ct);
        if (user == null) return NotFound(ApiResponse<bool>.Fail("Usuario no encontrado."));

        user.IsVerified = request.IsVerified;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return Ok(ApiResponse<bool>.Ok(true,
            request.IsVerified ? "Perfil verificado." : "Verificación retirada."));
    }

    [HttpPatch("posts/{id:guid}/status")]
    public async Task<IActionResult> Status(Guid id, UpdatePostStatusRequest request, CancellationToken ct)
    {
        var post = await db.Posts.FindAsync([id], ct);
        if (post == null) return NotFound(ApiResponse<bool>.Fail("Publicación no encontrada."));
        post.Status = request.Status;
        post.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return Ok(ApiResponse<bool>.Ok(true));
    }

    [HttpGet("posts/{id:guid}")]
    public async Task<IActionResult> Post(Guid id, CancellationToken ct)
    {
        var post = await db.Posts.AsNoTracking().Include(p => p.User).Include(p => p.Category)
            .Include(p => p.Images).Include(p => p.Reactions).Include(p => p.Confirmations)
            .FirstOrDefaultAsync(p => p.Id == id, ct);
        return post == null ? NotFound(ApiResponse<PostDto>.Fail("Publicación no encontrada."))
            : Ok(ApiResponse<PostDto>.Ok(RdReporta.Application.Services.PostService.MapToDto(post, post.User, post.Category, null)));
    }

    [HttpPut("categories/{id:int}")]
    [Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Category(int id, CreateCategoryRequest request, CancellationToken ct)
    {
        var category = await db.Categories.FindAsync([id], ct);
        if (category == null) return NotFound(ApiResponse<bool>.Fail("Categoría no encontrada."));
        var slug = request.Slug.Trim().ToLowerInvariant();
        if (await db.Categories.AnyAsync(c => c.Id != id && c.Slug == slug, ct))
            return BadRequest(ApiResponse<bool>.Fail("Ya existe una categoría con ese slug."));
        category.Name = request.Name.Trim();
        category.Slug = slug;
        category.Description = request.Description?.Trim();
        category.IconName = request.IconName.Trim();
        category.ColorHex = request.ColorHex;
        category.DisplayOrder = request.DisplayOrder;
        await db.SaveChangesAsync(ct);
        return Ok(ApiResponse<bool>.Ok(true));
    }
}

public record UpdatePostStatusRequest([EnumDataType(typeof(PostStatus))] PostStatus Status);
public record UpdateVerificationRequest(bool IsVerified);
