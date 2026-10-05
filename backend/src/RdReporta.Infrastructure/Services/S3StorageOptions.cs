namespace RdReporta.Infrastructure.Services;

public class S3StorageOptions
{
    public const string SectionName = "Storage";

    /// <summary>
    /// Storage provider: "Local" or "S3" (works for AWS S3, Cloudflare R2, MinIO, GCS interoperability).
    /// </summary>
    public string Provider { get; set; } = "Local";

    /// <summary>
    /// Service URL endpoint for S3-compatible providers (e.g. "https://<account_id>.r2.cloudflarestorage.com" for Cloudflare R2, or "https://storage.googleapis.com" for GCS).
    /// </summary>
    public string? ServiceUrl { get; set; }

    /// <summary>
    /// Name of the S3/R2 bucket.
    /// </summary>
    public string? BucketName { get; set; }

    /// <summary>
    /// Access Key ID.
    /// </summary>
    public string? AccessKey { get; set; }

    /// <summary>
    /// Secret Access Key.
    /// </summary>
    public string? SecretKey { get; set; }

    /// <summary>
    /// Region name (e.g. "auto" for Cloudflare R2, or "us-east-1" for AWS S3).
    /// </summary>
    public string? Region { get; set; } = "auto";

    /// <summary>
    /// Public CDN or custom domain URL base (e.g. "https://cdn.rdreporta.com" or "https://pub-xxxx.r2.dev").
    /// When specified, uploaded files return URLs pointing to this host.
    /// </summary>
    public string? PublicUrlBase { get; set; }

    /// <summary>
    /// Whether to force path style (true for MinIO/localstack, false for AWS S3 and Cloudflare R2).
    /// </summary>
    public bool ForcePathStyle { get; set; } = false;
}
