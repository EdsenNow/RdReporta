using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RdReporta.Application.Common.Interfaces;
using RdReporta.Api.Services;

namespace RdReporta.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/uploads/video/chunks")]
public class VideoChunksController(
    IWebHostEnvironment environment,
    ICurrentUserService currentUser,
    IStorageService? storageService = null) : ControllerBase
{
    private const int ChunkSize = 512 * 1024;
    private const long MaxSize = 150 * 1024 * 1024;

    [HttpPut("{uploadId:guid}")]
    [RequestSizeLimit(ChunkSize)]
    public async Task<IActionResult> Put(Guid uploadId, [FromQuery] long offset,
        [FromQuery] long total, [FromQuery] string extension, CancellationToken ct)
    {
        if (currentUser.UserId is not Guid userId) return Unauthorized();
        extension = extension.ToLowerInvariant();
        if (!new[] { ".mp4", ".mov", ".m4v", ".webm", ".3gp", ".mkv" }.Contains(extension)
            || total <= 0 || total > MaxSize || offset < 0 || offset >= total
            || offset % ChunkSize != 0)
            return BadRequest(new { message = "Datos del bloque de video inválidos." });

        var expected = (int)Math.Min(ChunkSize, total - offset);
        if (Request.ContentLength != expected)
            return BadRequest(new { message = "Tamaño del bloque de video inválido." });
        var bytes = new byte[expected];
        await Request.Body.ReadExactlyAsync(bytes, ct);
        if (offset == 0 && !HasExpectedVideoSignature(bytes, extension))
            return BadRequest(new { message = "El contenido no corresponde al formato de video indicado." });

        // Incomplete evidence is private and never served by static-file middleware.
        var staging = Path.Combine(environment.ContentRootPath, ".video-uploads");
        var destination = Path.Combine(environment.ContentRootPath, "wwwroot", "uploads");
        Directory.CreateDirectory(staging);
        Directory.CreateDirectory(destination);
        var name = $"{userId:N}_{uploadId:N}_{total}{extension}";
        var partial = Path.Combine(staging, name);
        var completed = Path.Combine(destination, name);
        if (System.IO.File.Exists(completed))
            return Ok(new { success = true, receivedBytes = total, url = $"/uploads/{name}" });

        // Remove abandoned transfers for this owner after a day; active files are locked.
        if (offset == 0)
        {
            foreach (var old in Directory.EnumerateFiles(staging, $"{userId:N}_*"))
            {
                if (System.IO.File.GetLastWriteTimeUtc(old) >= DateTime.UtcNow.AddDays(-1)) continue;
                try { System.IO.File.Delete(old); } catch (IOException) { }
            }
        }

        try
        {
            long received;
            await using (var file = new FileStream(partial, FileMode.OpenOrCreate,
                FileAccess.ReadWrite, FileShare.None, 65536, FileOptions.Asynchronous))
            {
                if (file.Length == offset)
                {
                    file.Position = offset;
                    try
                    {
                        await file.WriteAsync(bytes, ct);
                        await file.FlushAsync(ct);
                    }
                    catch
                    {
                        file.SetLength(offset);
                        throw;
                    }
                }
                else if (file.Length >= offset + expected)
                {
                    // A lost response may cause a repeated block. Never append it twice.
                    file.Position = offset;
                    var previous = new byte[expected];
                    await file.ReadExactlyAsync(previous, ct);
                    if (!previous.AsSpan().SequenceEqual(bytes))
                        return Conflict(new { message = "El bloque no coincide con el video recibido." });
                }
                else
                    return Conflict(new { message = "Falta un bloque anterior del video." });
                received = file.Length;
            }
            if (received == total)
            {
                TimeSpan duration;
                bool durationIsValid;
                await using (var assembled = System.IO.File.OpenRead(partial))
                {
                    durationIsValid = VideoSecurityHelper.TryReadDuration(assembled, extension, ct, out duration);
                }
                if (!durationIsValid)
                {
                    System.IO.File.Delete(partial);
                    return BadRequest(new { message = "No se pudo comprobar la duración del video." });
                }
                if (duration > VideoSecurityHelper.MaxDuration)
                {
                    System.IO.File.Delete(partial);
                    return BadRequest(new { message = "El video no puede superar los 3 minutos." });
                }

                string url;
                if (storageService != null && storageService.GetType().Name != "LocalStorageService")
                {
                    await using (var assembled = System.IO.File.OpenRead(partial))
                    {
                        var mimeType = extension switch
                        {
                            ".mp4" or ".m4v" => "video/mp4",
                            ".mov" => "video/quicktime",
                            ".webm" => "video/webm",
                            ".3gp" => "video/3gpp",
                            ".mkv" => "video/x-matroska",
                            _ => "application/octet-stream"
                        };
                        url = await storageService.UploadFileAsync(assembled, name, mimeType, userId, ct);
                    }
                    try { System.IO.File.Delete(partial); } catch { }
                }
                else
                {
                    System.IO.File.Move(partial, completed);
                    url = $"/uploads/{name}";
                }
                return Ok(new { success = true, receivedBytes = total, url });
            }
            return Ok(new { success = true, receivedBytes = received });
        }
        catch (IOException)
        {
            if (System.IO.File.Exists(completed))
                return Ok(new { success = true, receivedBytes = total, url = $"/uploads/{name}" });
            return StatusCode(503, new { message = "No se pudo guardar este bloque. Vuelve a intentarlo." });
        }
    }

    private static bool HasExpectedVideoSignature(ReadOnlySpan<byte> bytes, string extension)
    {
        var isMp4Family = bytes.Length >= 12
            && System.Text.Encoding.ASCII.GetString(bytes.Slice(4, 4)) == "ftyp";
        var isEbml = bytes.Length >= 4
            && bytes[..4].SequenceEqual(new byte[] { 0x1A, 0x45, 0xDF, 0xA3 });
        return extension switch
        {
            ".mp4" or ".mov" or ".m4v" or ".3gp" => isMp4Family,
            ".webm" or ".mkv" => isEbml,
            _ => false
        };
    }
}
