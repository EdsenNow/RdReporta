using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RdReporta.Api.Services;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Domain.Enums;

namespace RdReporta.Api.Controllers;

[ApiController]
[Route("api/posts/views")]
public class PostViewsController(IApplicationDbContext db, PostViewsBroadcaster broadcaster) : ControllerBase
{
    [HttpGet("live")]
    public async Task<IActionResult> Live([FromQuery, Required, MaxLength(7400)] string ids, CancellationToken ct)
    {
        var parts = ids.Split(',', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length is 0 or > 200 || parts.Any(p => !Guid.TryParse(p, out _)))
            return BadRequest(new { success = false, message = "Selecciona entre 1 y 200 reportes." });

        var requested = parts.Select(Guid.Parse).Distinct().ToArray();
        // Only counters belonging to publicly visible posts can be subscribed to.
        var allowed = await db.Posts.AsNoTracking()
            .Where(p => requested.Contains(p.Id) && p.Status != PostStatus.Hidden)
            .Select(p => p.Id).ToListAsync(ct);
        using var subscription = broadcaster.Subscribe(allowed.ToHashSet());
        Response.ContentType = "text/event-stream";
        Response.Headers.CacheControl = "no-cache, no-store";
        Response.Headers["X-Accel-Buffering"] = "no";
        HttpContext.Features.Get<IHttpResponseBodyFeature>()?.DisableBuffering();

        async Task Send(PostViewsUpdate update)
        {
            var json = JsonSerializer.Serialize(new { postId = update.PostId, viewsCount = update.ViewsCount });
            await Response.WriteAsync($"data: {json}\n\n", ct);
        }

        try
        {
            // Subscribe before reading: concurrent increments cannot be missed.
            var snapshot = await db.Posts.AsNoTracking().Where(p => allowed.Contains(p.Id))
                .Select(p => new PostViewsUpdate(p.Id, p.ViewsCount)).ToListAsync(ct);
            foreach (var update in snapshot) await Send(update);
            await Response.WriteAsync(": connected\n\n", ct);
            await Response.Body.FlushAsync(ct);

            while (!ct.IsCancellationRequested)
            {
                using var heartbeat = CancellationTokenSource.CreateLinkedTokenSource(ct);
                heartbeat.CancelAfter(TimeSpan.FromSeconds(15));
                try { await subscription.Reader.WaitToReadAsync(heartbeat.Token); }
                catch (OperationCanceledException) when (!ct.IsCancellationRequested) { }
                while (subscription.Reader.TryRead(out var update)) await Send(update);
                await Response.WriteAsync(": heartbeat\n\n", ct);
                await Response.Body.FlushAsync(ct);
            }
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested) { }
        return new EmptyResult();
    }
}
