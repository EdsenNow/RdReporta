using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Application.DTOs;
using RdReporta.Application.Services;
using RdReporta.Domain.Enums;

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
    [EnableRateLimiting("posts-policy")]
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
[EnableRateLimiting("posts-policy")]
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

        try
        {
            using var stream = file.OpenReadStream();
            var url = await _storageService.UploadFileAsync(stream, file.FileName, file.ContentType, ct);
            return Ok(new { success = true, url });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }
}
