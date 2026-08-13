using System.ComponentModel.DataAnnotations;
using TenderGo.Models.Entities;

public class Notification
{
    public int Id { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;

    public virtual ApplicationUser User { get; set; } = null!;

    [Required]
    public string Title { get; set; } = string.Empty;

    [Required]
    public string Message { get; set; } = string.Empty;

    [Required]

    public DateTime CreatedAt { get; set; }

    public bool IsRead { get; set; }
}