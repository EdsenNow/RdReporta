using Amazon;
using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RdReporta.Application.Common.Interfaces;

namespace RdReporta.Infrastructure.Services;

public class S3StorageService : IStorageService, IDisposable
{
    private readonly S3StorageOptions _options;
    private readonly ILogger<S3StorageService> _logger;
    private readonly IAmazonS3 _s3Client;
    private bool _disposed;

    public S3StorageService(IOptions<S3StorageOptions> options, ILogger<S3StorageService> logger)
    {
        _options = options.Value;
        _logger = logger;

        if (string.IsNullOrWhiteSpace(_options.BucketName))
            throw new InvalidOperationException("Storage:BucketName debe estar configurado para el proveedor S3/R2.");

        var s3Config = new AmazonS3Config
        {
            ForcePathStyle = _options.ForcePathStyle
        };

        if (!string.IsNullOrWhiteSpace(_options.ServiceUrl))
        {
            s3Config.ServiceURL = _options.ServiceUrl;
            if (!string.IsNullOrWhiteSpace(_options.Region) && !_options.Region.Equals("auto", StringComparison.OrdinalIgnoreCase))
            {
                s3Config.AuthenticationRegion = _options.Region;
            }
        }
        else if (!string.IsNullOrWhiteSpace(_options.Region) && !_options.Region.Equals("auto", StringComparison.OrdinalIgnoreCase))
        {
            s3Config.RegionEndpoint = RegionEndpoint.GetBySystemName(_options.Region);
        }
        else
        {
            s3Config.RegionEndpoint = RegionEndpoint.USEast1;
        }

        AWSCredentials credentials;
        if (!string.IsNullOrWhiteSpace(_options.AccessKey) && !string.IsNullOrWhiteSpace(_options.SecretKey))
        {
            credentials = new BasicAWSCredentials(_options.AccessKey, _options.SecretKey);
        }
        else
        {
            credentials = new AnonymousAWSCredentials();
        }

        _s3Client = new AmazonS3Client(credentials, s3Config);
    }

    public async Task<string> UploadFileAsync(
        Stream fileStream,
        string fileName,
        string contentType,
        Guid ownerUserId,
        CancellationToken cancellationToken = default)
    {
        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        var uniqueName = $"{ownerUserId:N}_{Guid.NewGuid():N}{ext}";
        var objectKey = $"uploads/{uniqueName}";

        var putRequest = new PutObjectRequest
        {
            BucketName = _options.BucketName,
            Key = objectKey,
            InputStream = fileStream,
            ContentType = string.IsNullOrWhiteSpace(contentType) ? "application/octet-stream" : contentType,
            AutoCloseStream = false
        };

        await _s3Client.PutObjectAsync(putRequest, cancellationToken);

        if (!string.IsNullOrWhiteSpace(_options.PublicUrlBase))
        {
            return $"{_options.PublicUrlBase.TrimEnd('/')}/uploads/{uniqueName}";
        }

        if (!string.IsNullOrWhiteSpace(_options.ServiceUrl))
        {
            return $"{_options.ServiceUrl.TrimEnd('/')}/{_options.BucketName}/uploads/{uniqueName}";
        }

        var region = string.IsNullOrWhiteSpace(_options.Region) || _options.Region.Equals("auto", StringComparison.OrdinalIgnoreCase)
            ? "us-east-1"
            : _options.Region;

        return $"https://{_options.BucketName}.s3.{region}.amazonaws.com/uploads/{uniqueName}";
    }

    public async Task DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(fileUrl)) return;

        try
        {
            var key = ExtractObjectKey(fileUrl);
            if (string.IsNullOrEmpty(key)) return;

            var deleteRequest = new DeleteObjectRequest
            {
                BucketName = _options.BucketName,
                Key = key
            };

            await _s3Client.DeleteObjectAsync(deleteRequest, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "No se pudo eliminar el archivo en S3/R2: {FileUrl}", fileUrl);
        }
    }

    private string ExtractObjectKey(string fileUrl)
    {
        if (Uri.TryCreate(fileUrl, UriKind.Absolute, out var uri))
        {
            var path = uri.AbsolutePath.TrimStart('/');
            if (!string.IsNullOrEmpty(_options.BucketName) && path.StartsWith($"{_options.BucketName}/", StringComparison.OrdinalIgnoreCase))
            {
                path = path[(_options.BucketName.Length + 1)..];
            }
            return path;
        }

        return fileUrl.TrimStart('/');
    }

    public void Dispose()
    {
        if (!_disposed)
        {
            _s3Client.Dispose();
            _disposed = true;
        }
    }
}
