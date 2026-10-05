using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.Formats.Webp;
using SixLabors.ImageSharp.Processing;

namespace RdReporta.Infrastructure.Security;

public static class ImageSecurityHelper
{
    // Limit decoded memory as well as the compressed request size.
    private const long MaxPixels = 24_000_000;

    public static async Task<MemoryStream> RemoveMetadataAsync(
        Stream input, string extension, CancellationToken cancellationToken = default)
    {
        IImageEncoder encoder = extension.ToLowerInvariant() switch
        {
            ".jpg" or ".jpeg" => new JpegEncoder { Quality = 90, SkipMetadata = true },
            ".png" => new PngEncoder { SkipMetadata = true },
            ".webp" => new WebpEncoder { Quality = 90, SkipMetadata = true },
            _ => throw new InvalidDataException("Formato de imagen no permitido.")
        };

        try
        {
            var start = input.Position;
            var info = await Image.IdentifyAsync(input, cancellationToken);
            if (info == null || (long)info.Width * info.Height > MaxPixels)
                throw new InvalidDataException("La imagen supera el límite de 24 megapíxeles.");
            input.Position = start;
            using var image = await Image.LoadAsync(
                new DecoderOptions { MaxFrames = 1 }, input, cancellationToken);
            // Apply orientation to pixels before removing the camera's EXIF profile.
            image.Mutate(operation => operation.AutoOrient());
            image.Metadata.ExifProfile = null;
            image.Metadata.XmpProfile = null;
            image.Metadata.IptcProfile = null;
            image.Metadata.IccProfile = null;
            var output = new MemoryStream();
            try
            {
                await image.SaveAsync(output, encoder, cancellationToken);
                output.Position = 0;
                return output;
            }
            catch
            {
                output.Dispose();
                throw;
            }
        }
        catch (Exception exception) when (exception is UnknownImageFormatException or InvalidImageContentException)
        {
            throw new InvalidDataException("La imagen está dañada o no se puede decodificar.", exception);
        }
    }
}
