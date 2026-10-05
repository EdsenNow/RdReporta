using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using RdReporta.Infrastructure.Persistence;

namespace RdReporta.Infrastructure.Services;

public sealed class PushNotificationWorker(
    IServiceScopeFactory scopes, IConfiguration configuration,
    ILogger<PushNotificationWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!configuration.GetValue<bool>("Firebase:Enabled"))
        {
            logger.LogInformation("Envío push desactivado. Configura Firebase:Enabled y las credenciales del servidor.");
            return;
        }

        FirebaseApp? app = null;
        try
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    app ??= FirebaseApp.Create(new AppOptions
                    {
                        Credential = await GoogleCredential.GetApplicationDefaultAsync(stoppingToken),
                        ProjectId = configuration["Firebase:ProjectId"]
                    }, "rdreporta-push");
                    if (await DeliverNextAsync(FirebaseMessaging.GetMessaging(app), stoppingToken))
                        continue;
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
                catch (Exception error)
                {
                    // Do not log credentials, tokens or the provider's response body.
                    logger.LogWarning("No se pudo procesar la cola push ({ErrorType}). Se reintentará.", error.GetType().Name);
                    await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
                }
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { }
        finally { app?.Delete(); }
    }

    private async Task<bool> DeliverNextAsync(FirebaseMessaging messaging, CancellationToken ct)
    {
        using var scope = scopes.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        // A row lock prevents two API instances from sending the same delivery concurrently.
        var rows = await db.PushDeliveries.FromSqlRaw("""
            SELECT * FROM "PushDeliveries"
            WHERE "CompletedAt" IS NULL AND "NextAttemptAt" <= CURRENT_TIMESTAMP
            ORDER BY "NextAttemptAt" LIMIT 1 FOR UPDATE SKIP LOCKED
            """).ToListAsync(ct);
        var delivery = rows.FirstOrDefault();
        if (delivery == null) return false;
        var notification = await db.UserNotifications.SingleAsync(x => x.Id == delivery.NotificationId, ct);
        var device = await db.DeviceRegistrations.SingleAsync(x => x.Id == delivery.DeviceRegistrationId, ct);
        var now = DateTime.UtcNow;

        if (notification.IsRead || notification.CreatedAt < now.AddDays(-1)
            || device.UserId != notification.UserId
            || !await db.Users.AnyAsync(x => x.Id == device.UserId && x.IsActive, ct)
            || (notification.PostId.HasValue && !await db.Posts.AnyAsync(
                x => x.Id == notification.PostId && x.Status != RdReporta.Domain.Enums.PostStatus.Hidden, ct)))
        {
            delivery.CompletedAt = now;
        }
        else
        {
            delivery.Attempts++;
            var data = new Dictionary<string, string>
            {
                ["notificationId"] = notification.Id.ToString(),
                ["userId"] = notification.UserId.ToString(),
                ["type"] = notification.Type
            };
            if (notification.PostId.HasValue) data["postId"] = notification.PostId.Value.ToString();
            try
            {
                using var timeout = CancellationTokenSource.CreateLinkedTokenSource(ct);
                timeout.CancelAfter(TimeSpan.FromSeconds(20));
                await messaging.SendAsync(new Message
                {
                    // Flutter Messaging still supplies registration tokens, not installation IDs.
#pragma warning disable CS0618
                    Token = device.Token,
#pragma warning restore CS0618
                    Notification = new Notification { Title = "RDReporta", Body = notification.Message },
                    Data = data,
                    Android = new AndroidConfig
                    {
                        Priority = Priority.High,
                        TimeToLive = TimeSpan.FromDays(1),
                        Notification = new AndroidNotification
                        {
                            ChannelId = "rdreporta_notifications", Tag = notification.Id.ToString(),
                            Icon = "ic_notification", Color = "#eb6f92", Sound = "default"
                        }
                    },
                    Apns = new ApnsConfig
                    {
                        Headers = new Dictionary<string, string>
                        {
                            ["apns-collapse-id"] = notification.Id.ToString(),
                            ["apns-expiration"] = new DateTimeOffset(now.AddDays(1)).ToUnixTimeSeconds().ToString()
                        },
                        Aps = new Aps { Sound = "default" }
                    }
                }, timeout.Token);
                delivery.CompletedAt = now;
            }
            catch (FirebaseMessagingException error) when (error.MessagingErrorCode == MessagingErrorCode.Unregistered)
            {
                db.DeviceRegistrations.Remove(device);
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested) { throw; }
            catch (Exception error)
            {
                var code = (error as FirebaseMessagingException)?.MessagingErrorCode;
                logger.LogWarning("Entrega push {DeliveryId}, intento {Attempt}: {ErrorCode}.",
                    delivery.Id, delivery.Attempts, code?.ToString() ?? error.GetType().Name);
                if (delivery.Attempts >= 8 || code is MessagingErrorCode.InvalidArgument or MessagingErrorCode.SenderIdMismatch)
                    delivery.CompletedAt = now;
                else
                    delivery.NextAttemptAt = now.AddSeconds(Math.Min(3600, 30 * Math.Pow(2, delivery.Attempts - 1)));
            }
        }
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return true;
    }
}
