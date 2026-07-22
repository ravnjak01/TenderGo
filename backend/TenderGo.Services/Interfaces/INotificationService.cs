using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Interfaces;

public interface INotificationService
{
    Task<PagedResult<NotificationDTO>> GetMyNotificationsAsync(string userId, PagedSearchRequest request);
    Task<NotificationDTO> MarkAsReadAsync(int id, string userId);
    Task MarkAllAsReadAsync(string userId);
    Task DeleteAsync(int id, string userId);
}