using System.ComponentModel.DataAnnotations;
using TenderGo.Models.Entities;

public class PasswordResetCode
{
    public int Id { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;

    public virtual ApplicationUser User { get; set; } = null!;

    [Required]
    public string Code { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime ExpiryTime { get; set; }

    public bool IsUsed { get; set; }

    public DateTime? UsedAt { get; set; }

    public int Attempts { get; set; } = 0;

    public bool IsInvalidated { get; set; }

    [Required]
    public string Salt { get; set; } = string.Empty;
}