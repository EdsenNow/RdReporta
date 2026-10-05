using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Application.DTOs;
using RdReporta.Application.Services;
using RdReporta.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using RdReporta.Application.Common.Models;
using RdReporta.Infrastructure.Security;
using RdReporta.Api.Services;

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
            totalViews = await visible.SumAsync(p => p.ViewsCount, ct)
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
            .Include(p => p.Reactions)
            .OrderByDescending(p => p.CreatedAt).Skip((page - 1) * 20).Take(20).ToListAsync(ct);
        return Ok(ApiResponse<PagedResult<PostDto>>.Ok(new PagedResult<PostDto> {
            Items = posts.Select(p => RdReporta.Application.Services.PostService.MapToDto(p, p.User, p.Category, _currentUserService.UserId)).ToList(),
            TotalCount = total, PageNumber = page, PageSize = 20
        }));
    }

    [Authorize]
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteOwnPost(Guid id, CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _postService.DeletePostAsync(id, _currentUserService.UserId.Value, ct);
        return response.Success ? Ok(response) : NotFound(response);
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
    [HttpPost("{id:guid}/views")]
    public async Task<IActionResult> RecordView(Guid id, [FromServices] PostViewsBroadcaster broadcaster, CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _postService.RecordViewAsync(id, _currentUserService.UserId.Value, ct);
        if (response.Success) broadcaster.Publish(id, response.Data);
        return response.Success ? Ok(response) : NotFound(response);
    }

    [Authorize]
    [HttpPost("{id:guid}/reactions")]
    public async Task<IActionResult> ToggleReaction(Guid id, [FromBody] PostReactionRequest request, [FromServices] PostViewsBroadcaster broadcaster, CancellationToken ct)
    {
        if (_currentUserService.UserId == null) return Unauthorized();
        var response = await _postService.ToggleReactionAsync(id, request.ReactionType, _currentUserService.UserId.Value, ct);
        if (!response.Success) return BadRequest(response);
        var view = await _postService.RecordViewAsync(id, _currentUserService.UserId.Value, ct);
        if (view.Success) broadcaster.Publish(id, view.Data);
        return Ok(new { response.Success, response.Data, response.Message,
            ViewsCount = view.Success ? (int?)view.Data : null });
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
    private readonly ICurrentUserService _currentUserService;

    public UploadsController(IStorageService storageService, ICurrentUserService currentUserService)
    {
        _storageService = storageService;
        _currentUserService = currentUserService;
    }

    [Authorize]
    [HttpPost("image")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(11 * 1024 * 1024)]
    public async Task<IActionResult> UploadImage(IFormFile file, CancellationToken ct)
    {
        if (_currentUserService.UserId is not Guid userId) return Unauthorized();
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
        MemoryStream sanitized;
        try
        {
            sanitized = await ImageSecurityHelper.RemoveMetadataAsync(stream, ext, ct);
        }
        catch (InvalidDataException)
        {
            return BadRequest(new { success = false, message = "La estructura de la imagen no es válida." });
        }
        await using (sanitized)
        {
            var url = await _storageService.UploadFileAsync(
                sanitized, file.FileName, file.ContentType, userId, ct);
            return Ok(new { success = true, url });
        }
    }

    [Authorize]
    [HttpPost("video")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(150 * 1024 * 1024)]
    public async Task<IActionResult> UploadVideo(IFormFile file, CancellationToken ct)
    {
        if (_currentUserService.UserId is not Guid userId) return Unauthorized();
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { success = false, message = "Debe proporcionar un video válido." });
        }

        if (file.Length > 150 * 1024 * 1024) // 150MB limit
        {
            return BadRequest(new { success = false, message = "El tamaño del video no puede superar 150 MB." });
        }

        var allowedExtensions = new[] { ".mp4", ".mov", ".m4v", ".webm", ".3gp", ".mkv" };
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(ext))
        {
            return BadRequest(new { success = false, message = "Formato de video no permitido (.mp4, .mov, .m4v, .webm, .3gp, .mkv)." });
        }

        using var stream = file.OpenReadStream();
        var header = new byte[16];
        var read = await stream.ReadAsync(header, ct);
        var isMp4Family = read >= 12 && System.Text.Encoding.ASCII.GetString(header, 4, 4) == "ftyp";
        var isWebMOrMkv = read >= 4 && header.AsSpan(0, 4).SequenceEqual(new byte[] { 0x1A, 0x45, 0xDF, 0xA3 });
        var valid = ext switch
        {
            ".mp4" or ".mov" or ".m4v" or ".3gp" => isMp4Family,
            ".webm" or ".mkv" => isWebMOrMkv,
            _ => false
        };
        if (!valid)
            return BadRequest(new { success = false, message = "El archivo no corresponde al formato de video indicado." });

        stream.Position = 0;
        if (!VideoSecurityHelper.TryReadDuration(stream, ext, ct, out var duration))
            return BadRequest(new { success = false, message = "No se pudo comprobar la duración del video." });
        if (duration > VideoSecurityHelper.MaxDuration)
            return BadRequest(new { success = false, message = "El video no puede superar los 3 minutos." });

        stream.Position = 0;
        var url = await _storageService.UploadFileAsync(stream, file.FileName, file.ContentType ?? "video/mp4", userId, ct);

        return Ok(new { success = true, url });
    }
}
