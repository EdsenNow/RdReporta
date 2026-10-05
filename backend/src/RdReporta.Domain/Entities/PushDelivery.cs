namespace RdReporta.Domain.Entities;

public class PushDelivery
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid NotificationId { get; set; }
    public UserNotification Notification { get; set; } = null!;
    public Guid DeviceRegistrationId { get; set; }
    public DeviceRegistration DeviceRegistration { get; set; } = null!;
    public int Attempts { get; set; }
    public DateTime NextAttemptAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }
}
