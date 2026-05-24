namespace TenderGo.Models.DTOs;

public class NotificationDTO
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = "general";
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? TenderId { get; set; }
}