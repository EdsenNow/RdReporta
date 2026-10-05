using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.FileProviders;
using RdReporta.Api.Controllers;
using RdReporta.Application.Common.Interfaces;
using System.Security.Cryptography;

var root = Path.Combine(Path.GetTempPath(), "rdreporta-video-check-" + Guid.NewGuid());
Directory.CreateDirectory(root);
try
{
    var environment = new TestEnvironment { ContentRootPath = root };
    var controller = new VideoChunksController(environment, new TestUser());
    var id = Guid.NewGuid();
    const int chunkSize = 512 * 1024;
    const int total = 54735667;
    var block = new byte[chunkSize];
    RandomNumberGenerator.Fill(block);
// Minimal ISO base media signature used by MP4/MOV/3GP containers.
block[4] = (byte)'f'; block[5] = (byte)'t'; block[6] = (byte)'y'; block[7] = (byte)'p';
    using var expectedHash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
    async Task<IActionResult> Send(VideoChunksController target, long offset, byte[] bytes)
    {
        target.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };
        target.Request.ContentLength = bytes.Length;
        target.Request.Body = new MemoryStream(bytes);
        return await target.Put(id, offset, total, ".mp4", CancellationToken.None);
    }
    for (var offset = 0; offset < total; offset += chunkSize)
    {
        var bytes = block[..Math.Min(chunkSize, total - offset)];
        expectedHash.AppendData(bytes);
        if (await Send(controller, offset, bytes) is not OkObjectResult)
            throw new Exception("Block was rejected.");
        // Simulate a lost acknowledgement and resend every block.
        if (await Send(controller, offset, bytes) is not OkObjectResult)
            throw new Exception("Repeated block was not idempotent.");
        if (offset == 0)
        {
            var wrong = (byte[])bytes.Clone();
            wrong[0] ^= 255;
            if (await Send(controller, offset, wrong) is not ConflictObjectResult)
                throw new Exception("Conflicting bytes were accepted.");
            var anotherOwner = new VideoChunksController(environment, new TestUser());
            if (await Send(anotherOwner, chunkSize, block) is not ConflictObjectResult)
                throw new Exception("Another owner could resume the upload.");
        }
    }
    var finished = Directory.GetFiles(Path.Combine(root, "wwwroot", "uploads")).Single();
    await using var stream = File.OpenRead(finished);
    var actualHash = await SHA256.HashDataAsync(stream);
    if (!actualHash.SequenceEqual(expectedHash.GetHashAndReset()) || stream.Length != total)
        throw new Exception("Completed video content differs from original.");
    Console.WriteLine("PASS: 52.2 MiB, duplicate blocks, content integrity, conflicting bytes and owner isolation.");
}
finally
{
    Directory.Delete(root, recursive: true);
}

sealed class TestUser : ICurrentUserService
{
    public Guid? UserId { get; } = Guid.NewGuid();
    public string? Email => null;
    public bool IsAuthenticated => true;
}

sealed class TestEnvironment : IWebHostEnvironment
{
    public string ContentRootPath { get; set; } = "";
    public string WebRootPath { get; set; } = "";
    public string EnvironmentName { get; set; } = "Testing";
    public string ApplicationName { get; set; } = "VideoUploadChecks";
    public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
    public IFileProvider WebRootFileProvider { get; set; } = new NullFileProvider();
}
