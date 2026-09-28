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

    public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType, CancellationToken cancellationToken = default)
    {
        // 1. Validar firma criptográfica (Magic Bytes)
        if (!Security.ImageSecurityHelper.TryValidateImageSignature(fileStream, out var safeExtension, out _))
        {
            throw new InvalidOperationException("El archivo no posee una firma de imagen válida (.jpg, .png, .webp).");
        }

        var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        var uploadsFolder = Path.Combine(webRoot, "uploads");

        if (!Directory.Exists(uploadsFolder))
        {
            Directory.CreateDirectory(uploadsFolder);
        }

        // 2. Sanitizar metadatos EXIF / GPS para resguardar la privacidad del ciudadano
        await using var sanitizedStream = await Security.ImageSecurityHelper.SanitizeImageAsync(fileStream, safeExtension, cancellationToken);

        // 3. Generar nombre de archivo 100% seguro con GUID puro y extensión verificada
        var uniqueName = $"{Guid.NewGuid()}{safeExtension}";
        var filePath = Path.Combine(uploadsFolder, uniqueName);

        await using (var output = new FileStream(filePath, FileMode.Create, FileAccess.Write, FileShare.None))
        {
            await sanitizedStream.CopyToAsync(output, cancellationToken);
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
