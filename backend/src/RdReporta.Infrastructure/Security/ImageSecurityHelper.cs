using System.Text;

namespace RdReporta.Infrastructure.Security;

/// <summary>
/// Proporciona validación criptográfica de firmas (Magic Bytes) y sanitización
/// de metadatos EXIF/GPS para proteger la privacidad de los ciudadanos dominicanos.
/// </summary>
public static class ImageSecurityHelper
{
    private static readonly byte[] JpegHeader = [0xFF, 0xD8, 0xFF];
    private static readonly byte[] PngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    private static readonly byte[] RiffHeader = [0x52, 0x49, 0x46, 0x46]; // "RIFF"
    private static readonly byte[] WebpHeader = [0x57, 0x45, 0x42, 0x50]; // "WEBP"

    /// <summary>
    /// Valida que el flujo de datos coincida con los magic bytes reales de una imagen válida (.jpg, .png, .webp).
    /// </summary>
    public static bool TryValidateImageSignature(Stream stream, out string extension, out string contentType)
    {
        extension = string.Empty;
        contentType = string.Empty;

        if (stream == null || !stream.CanRead || stream.Length < 12)
        {
            return false;
        }

        var header = new byte[12];
        var initialPos = stream.Position;
        int bytesRead = stream.Read(header, 0, header.Length);
        stream.Position = initialPos; // Rebobinar flujo

        if (bytesRead < 12) return false;

        // 1. JPEG (FF D8 FF)
        if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
        {
            extension = ".jpg";
            contentType = "image/jpeg";
            return true;
        }

        // 2. PNG (89 50 4E 47 0D 0A 1A 0A)
        if (header.AsSpan(0, 8).SequenceEqual(PngHeader))
        {
            extension = ".png";
            contentType = "image/png";
            return true;
        }

        // 3. WebP ("RIFF" .... "WEBP")
        if (header.AsSpan(0, 4).SequenceEqual(RiffHeader) &&
            header.AsSpan(8, 4).SequenceEqual(WebpHeader))
        {
            extension = ".webp";
            contentType = "image/webp";
            return true;
        }

        return false;
    }

    /// <summary>
    /// Remueve metadatos EXIF / etiquetas GPS de imágenes JPEG para impedir que coordenadas
    /// residenciales privadas del ciudadano sean expuestas a través de la imagen subida.
    /// </summary>
    public static async Task<Stream> SanitizeImageAsync(Stream inputStream, string extension, CancellationToken ct = default)
    {
        if (extension.Equals(".jpg", StringComparison.OrdinalIgnoreCase) ||
            extension.Equals(".jpeg", StringComparison.OrdinalIgnoreCase))
        {
            return await StripJpegExifAsync(inputStream, ct);
        }

        // Para formatos sin riesgo directo de GPS EXIF en este flujo, se copia a memoria
        var cleanMs = new MemoryStream();
        await inputStream.CopyToAsync(cleanMs, ct);
        cleanMs.Position = 0;
        return cleanMs;
    }

    private static async Task<MemoryStream> StripJpegExifAsync(Stream input, CancellationToken ct)
    {
        var output = new MemoryStream();
        var buffer = new byte[input.Length];
        input.Position = 0;
        int totalRead = await input.ReadAsync(buffer.AsMemory(0, (int)input.Length), ct);

        if (totalRead < 4 || buffer[0] != 0xFF || buffer[1] != 0xD8)
        {
            input.Position = 0;
            await input.CopyToAsync(output, ct);
            output.Position = 0;
            return output;
        }

        // Escribir SOI (Start of Image)
        output.WriteByte(0xFF);
        output.WriteByte(0xD8);

        int pos = 2;
        while (pos < totalRead - 1)
        {
            if (buffer[pos] != 0xFF)
            {
                // Segmento no estándar o datos comprimidos, copiar el resto y terminar
                output.Write(buffer, pos, totalRead - pos);
                break;
            }

            byte marker = buffer[pos + 1];
            pos += 2;

            // Marcadores de 0 bytes de longitud (RST, SOI, EOI, TEM)
            if (marker == 0xD9) // EOI
            {
                output.WriteByte(0xFF);
                output.WriteByte(marker);
                break;
            }
            if (marker is >= 0xD0 and <= 0xD7 or 0x01)
            {
                output.WriteByte(0xFF);
                output.WriteByte(marker);
                continue;
            }

            if (pos + 1 >= totalRead) break;

            int segmentLength = (buffer[pos] << 8) | buffer[pos + 1];
            if (segmentLength < 2 || pos + segmentLength > totalRead)
            {
                // Segmento truncado, escribir y salir
                break;
            }

            // Marcador APP1 (0xE1) que contiene EXIF (incluyendo coordenadas GPS)
            bool isExifApp1 = false;
            if (marker == 0xE1 && segmentLength >= 8)
            {
                // "Exif\0\0"
                if (buffer[pos + 2] == 'E' && buffer[pos + 3] == 'x' &&
                    buffer[pos + 4] == 'i' && buffer[pos + 5] == 'f' &&
                    buffer[pos + 6] == 0 && buffer[pos + 7] == 0)
                {
                    isExifApp1 = true;
                }
            }

            if (!isExifApp1)
            {
                // Conservar marcador y payload
                output.WriteByte(0xFF);
                output.WriteByte(marker);
                output.Write(buffer, pos, segmentLength);
            }

            pos += segmentLength;

            // Si es SOS (Start of Scan 0xDA), los datos comprimidos siguen directamente hasta EOI
            if (marker == 0xDA)
            {
                output.Write(buffer, pos, totalRead - pos);
                break;
            }
        }

        output.Position = 0;
        return output;
    }
}
