using Microsoft.AspNetCore.Hosting;
using RdReporta.Application.Common.Interfaces;

namespace RdReporta.Infrastructure.Services;

public class LocalStorageService : IStorageService
{
    private readonly IWebHostEnvironment _environment;

    public LocalStorageService(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType, Guid ownerUserId, CancellationToken cancellationToken = default)
    {
        var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        var uploadsFolder = Path.Combine(webRoot, "uploads");

        if (!Directory.Exists(uploadsFolder))
        {
            Directory.CreateDirectory(uploadsFolder);
        }

        var uniqueName = $"{ownerUserId:N}_{Guid.NewGuid():N}{Path.GetExtension(fileName).ToLowerInvariant()}";
        var filePath = Path.Combine(uploadsFolder, uniqueName);

        using (var output = new FileStream(filePath, FileMode.Create))
        {
            await fileStream.CopyToAsync(output, cancellationToken);
        }

        return $"/uploads/{uniqueName}";
    }

    public Task DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        try
        {
            var fileName = Path.GetFileName(fileUrl);
            var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var filePath = Path.Combine(webRoot, "uploads", fileName);

            if (File.Exists(filePath))
            {
                File.Delete(filePath);
            }
        }
        catch
        {
            // Ignore if file doesn't exist
        }

        return Task.CompletedTask;
    }
}
