namespace RdReporta.Application.Common;

public static class UploadReference
{
    public static bool IsOwned(string? url, Guid ownerId, IReadOnlySet<string> extensions)
    {
        if (string.IsNullOrWhiteSpace(url)) return false;

        string fileName;
        if (Uri.TryCreate(url, UriKind.Absolute, out var uri))
        {
            if (!uri.Scheme.Equals("http", StringComparison.OrdinalIgnoreCase) &&
                !uri.Scheme.Equals("https", StringComparison.OrdinalIgnoreCase))
                return false;

            if (!string.IsNullOrEmpty(uri.Query)) return false;

            fileName = Path.GetFileName(uri.AbsolutePath);
            if (!uri.AbsolutePath.EndsWith($"/uploads/{fileName}", StringComparison.OrdinalIgnoreCase))
                return false;
        }
        else
        {
            fileName = Path.GetFileName(url);
            if (url != $"/uploads/{fileName}") return false;
        }

        if (!fileName.StartsWith($"{ownerId:N}_", StringComparison.OrdinalIgnoreCase))
            return false;

        var stem = Path.GetFileNameWithoutExtension(fileName);
        if (stem.Length <= 33) return false;
        var suffix = stem[33..].Split('_');
        if (suffix.Length is < 1 or > 2 || !Guid.TryParseExact(suffix[0], "N", out _)) return false;
        if (suffix.Length == 2 && (!long.TryParse(suffix[1], out var total) || total <= 0)) return false;
        return extensions.Contains(Path.GetExtension(fileName));
    }
}
