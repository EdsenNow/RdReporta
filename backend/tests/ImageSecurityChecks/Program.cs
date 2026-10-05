using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Metadata.Profiles.Exif;
using SixLabors.ImageSharp.Formats;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.Formats.Png.Chunks;
using SixLabors.ImageSharp.Formats.Webp;
using RdReporta.Infrastructure.Security;
using RdReporta.Application.Common;

foreach (var (extension, encoder) in new (string, IImageEncoder)[]
{
    (".jpg", new JpegEncoder()), (".png", new PngEncoder()), (".webp", new WebpEncoder())
})
{
    using var image = new Image<Rgb24>(10, 20);
    image.Metadata.ExifProfile = new ExifProfile();
    image.Metadata.ExifProfile.SetValue(ExifTag.Orientation, (ushort)6);
    image.Metadata.ExifProfile.SetValue(ExifTag.GPSLatitudeRef, "N");
    image.Metadata.ExifProfile.SetValue(ExifTag.Artist, "Private author");
    if (extension == ".png")
        image.Metadata.GetPngMetadata().TextData.Add(new PngTextData("Author", "Private author", "", ""));
    using var input = new MemoryStream();
    await image.SaveAsync(input, encoder);
    input.Position = 0;
    using var sanitized = await ImageSecurityHelper.RemoveMetadataAsync(input, extension);
    using var decoded = await Image.LoadAsync(sanitized);
    if (decoded.Width != 20 || decoded.Height != 10)
        throw new Exception($"{extension}: image orientation changed.");
    if (decoded.Metadata.ExifProfile != null || decoded.Metadata.XmpProfile != null
        || decoded.Metadata.IptcProfile != null)
        throw new Exception($"{extension}: private metadata survived.");
    if (extension == ".png" && decoded.Metadata.GetPngMetadata().TextData.Count != 0)
        throw new Exception("PNG private text survived.");
}

try
{
    using var damaged = new MemoryStream(new byte[] { 0xFF, 0xD8, 0xFF, 0xDA, 0, 2 });
    using var unexpected = await ImageSecurityHelper.RemoveMetadataAsync(damaged, ".jpg");
    throw new Exception("Damaged image was accepted.");
}
catch (InvalidDataException) { }

var owner = Guid.NewGuid();
var allowed = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".jpg" };
var name = $"{owner:N}_{Guid.NewGuid():N}.jpg";
if (!UploadReference.IsOwned($"/uploads/{name}", owner, allowed)
    || UploadReference.IsOwned($"/uploads/{name}", Guid.NewGuid(), allowed)
    || UploadReference.IsOwned($"/uploads/../{name}", owner, allowed)
    || UploadReference.IsOwned($"/uploads/{name}?x=1", owner, allowed))
    throw new Exception("Upload owner or path checks failed.");

Console.WriteLine("PASS: real JPEG/PNG/WebP decode, orientation, metadata, damaged files and upload ownership.");
