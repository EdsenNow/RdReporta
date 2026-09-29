using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Application.DTOs;
using RdReporta.Application.Services;
using RdReporta.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using RdReporta.Application.Common.Models;

namespace RdReporta.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PostsController : ControllerBase
{
    private readonly IPostService _postService;
    private readonly ICurrentUserService _currentUserService;

    public PostsController(IPostService postService, ICurrentUserService currentUserService)
    {
        _postService = postService;
        _currentUserService = currentUserService;
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CreatePost([FromBody] CreatePostRequest request, CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _postService.CreatePostAsync(request, _currentUserService.UserId.Value, ct);
        if (!response.Success) return BadRequest(response);
        return CreatedAtAction(nameof(GetPostById), new { id = response.Data!.Id }, response);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetPostById(Guid id, CancellationToken ct)
    {
        var response = await _postService.GetByIdAsync(id, _currentUserService.UserId, ct);
        if (!response.Success) return NotFound(response);
        return Ok(response);
    }

    [HttpGet("recent")]
    public async Task<IActionResult> GetRecentPosts(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] int? categoryId = null,
        CancellationToken ct = default)
    {
        var response = await _postService.GetRecentAsync(page, pageSize, categoryId, _currentUserService.UserId, ct);
        return Ok(response);
    }

    [HttpGet("stats")]
    public async Task<IActionResult> Stats([FromServices] IApplicationDbContext db, CancellationToken ct)
    {
        var visible = db.Posts.Where(p => p.Status == PostStatus.Active || p.Status == PostStatus.Resolved);
        return Ok(new { success = true, data = new {
            totalPosts = await visible.CountAsync(ct),
            activePosts = await visible.CountAsync(p => p.Status == PostStatus.Active, ct),
            resolvedPosts = await visible.CountAsync(p => p.Status == PostStatus.Resolved, ct),
            totalConfirmations = await visible.SumAsync(p => p.ConfirmationsCount, ct)
        }});
    }

    [Authorize]
    [HttpGet("mine")]
    public async Task<IActionResult> Mine([FromServices] IApplicationDbContext db,
        [FromQuery, Range(1, int.MaxValue)] int page = 1, CancellationToken ct = default)
    {
        var query = db.Posts.AsNoTracking().Where(p => p.UserId == _currentUserService.UserId);
        var total = await query.CountAsync(ct);
        var posts = await query.Include(p => p.User).Include(p => p.Category).Include(p => p.Images)
            .Include(p => p.Reactions).Include(p => p.Confirmations)
            .OrderByDescending(p => p.CreatedAt).Skip((page - 1) * 20).Take(20).ToListAsync(ct);
        return Ok(ApiResponse<PagedResult<PostDto>>.Ok(new PagedResult<PostDto> {
            Items = posts.Select(p => RdReporta.Application.Services.PostService.MapToDto(p, p.User, p.Category, _currentUserService.UserId)).ToList(),
            TotalCount = total, PageNumber = page, PageSize = 20
        }));
    }

    [HttpGet("nearby")]
    public async Task<IActionResult> GetNearbyPosts([FromQuery] NearbyPostsRequest request, CancellationToken ct)
    {
        var response = await _postService.GetNearbyAsync(request, _currentUserService.UserId, ct);
        return Ok(response);
    }

    [HttpGet("popular")]
    public async Task<IActionResult> GetPopularPosts(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var response = await _postService.GetPopularThisWeekAsync(page, pageSize, _currentUserService.UserId, ct);
        return Ok(response);
    }

    [HttpGet("map")]
    public async Task<IActionResult> GetMapPins(
        [FromQuery] double minLat = 17.5,
        [FromQuery] double maxLat = 20.0,
        [FromQuery] double minLng = -72.0,
        [FromQuery] double maxLng = -68.3,
        [FromQuery] int? categoryId = null,
        CancellationToken ct = default)
    {
        var response = await _postService.GetMapPinsAsync(minLat, maxLat, minLng, maxLng, categoryId, ct);
        return Ok(response);
    }

    [Authorize]
    [HttpPost("{id:guid}/reactions")]
    public async Task<IActionResult> ToggleReaction(Guid id, [FromBody] PostReactionRequest request, CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _postService.ToggleReactionAsync(id, request.ReactionType, _currentUserService.UserId.Value, ct);
        if (!response.Success) return BadRequest(response);
        return Ok(response);
    }

    [Authorize]
    [HttpPost("{id:guid}/confirm")]
    public async Task<IActionResult> ConfirmPost(Guid id, [FromBody] PostConfirmationRequest request, CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _postService.ConfirmPostAsync(id, request, _currentUserService.UserId.Value, ct);
        if (!response.Success) return BadRequest(response);
        return Ok(response);
    }
}

[ApiController]
[Route("api/[controller]")]
public class CategoriesController : ControllerBase
{
    private readonly ICategoryService _categoryService;

    public CategoriesController(ICategoryService categoryService)
    {
        _categoryService = categoryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetCategories(CancellationToken ct)
    {
        var response = await _categoryService.GetActiveCategoriesAsync(ct);
        return Ok(response);
    }

    [Authorize(Roles = "Administrador")]
    [HttpPost]
    public async Task<IActionResult> CreateCategory([FromBody] CreateCategoryRequest request, CancellationToken ct)
    {
        var response = await _categoryService.CreateCategoryAsync(request, ct);
        if (!response.Success) return BadRequest(response);
        return Ok(response);
    }
}

[ApiController]
[Route("api/[controller]")]
public class ModerationController : ControllerBase
{
    private readonly IModerationService _moderationService;
    private readonly ICurrentUserService _currentUserService;

    public ModerationController(IModerationService moderationService, ICurrentUserService currentUserService)
    {
        _moderationService = moderationService;
        _currentUserService = currentUserService;
    }

    [Authorize]
    [HttpPost("report")]
    public async Task<IActionResult> ReportPost([FromBody] CreateModerationReportRequest request, CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _moderationService.ReportPostAsync(request, _currentUserService.UserId.Value, ct);
        if (!response.Success) return BadRequest(response);
        return Ok(response);
    }

    [Authorize(Roles = "Moderador,Administrador")]
    [HttpGet("reports")]
    public async Task<IActionResult> GetReports([FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken ct = default)
    {
        var response = await _moderationService.GetPendingReportsAsync(page, pageSize, ct);
        return Ok(response);
    }

    [Authorize(Roles = "Moderador,Administrador")]
    [HttpPost("reports/{id:guid}/resolve")]
    public async Task<IActionResult> ResolveReport(Guid id, [FromBody] ResolveModerationRequest request, CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _moderationService.ResolveReportAsync(id, request, _currentUserService.UserId.Value, ct);
        if (!response.Success) return BadRequest(response);
        return Ok(response);
    }
}

[ApiController]
[Route("api/[controller]")]
public class UploadsController : ControllerBase
{
    private readonly IStorageService _storageService;

    public UploadsController(IStorageService storageService)
    {
        _storageService = storageService;
    }

    [Authorize]
    [HttpPost("image")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(11 * 1024 * 1024)]
    public async Task<IActionResult> UploadImage(IFormFile file, CancellationToken ct)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { success = false, message = "Debe proporcionar una imagen válida." });
        }

        if (file.Length > 10 * 1024 * 1024) // 10MB limit
        {
            return BadRequest(new { success = false, message = "El tamaño de la imagen no puede superar 10 MB." });
        }

        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(ext))
        {
            return BadRequest(new { success = false, message = "Formato de imagen no permitido (.jpg, .jpeg, .png, .webp)." });
        }

        using var stream = file.OpenReadStream();
        var header = new byte[12];
        var read = await stream.ReadAsync(header, ct);
        var valid = read >= 12 && (ext switch {
            ".jpg" or ".jpeg" => header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF,
            ".png" => header.AsSpan(0, 8).SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 }),
            ".webp" => System.Text.Encoding.ASCII.GetString(header, 0, 4) == "RIFF" && System.Text.Encoding.ASCII.GetString(header, 8, 4) == "WEBP",
            _ => false
        });
        if (!valid) return BadRequest(new { success = false, message = "El archivo no corresponde al formato de imagen indicado." });
        stream.Position = 0;
        var url = await _storageService.UploadFileAsync(stream, file.FileName, file.ContentType, ct);

        return Ok(new { success = true, url });
    }
}
