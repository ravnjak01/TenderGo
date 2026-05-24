using TenderGo.Models.DTOs;

namespace TenderGo.Services.Interfaces;

public interface INotificationService
{
    Task<List<NotificationDTO>> GetMyNotificationsAsync(string userId);
    Task<NotificationDTO> MarkAsReadAsync(int id, string userId);
    Task MarkAllAsReadAsync(string userId);
    Task DeleteAsync(int id, string userId);
}