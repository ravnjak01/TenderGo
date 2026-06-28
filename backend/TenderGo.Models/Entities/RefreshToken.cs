using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using TenderGo.Models.Entities;

public class RefreshToken : BaseEntity
{
    public int Id { get; set; }

    [Required]
    [MaxLength(200)]
    public string Token { get; set; } = string.Empty;

    [Required]
    public string UserId { get; set; } = string.Empty;

    public ApplicationUser User { get; set; } = null!;

    public DateTime Expires { get; set; }

    [NotMapped]
    public bool IsExpired => DateTime.UtcNow >= Expires;

    public bool IsRevoked { get; set; }

    public DateTime? RevokedAt { get; set; }

    [NotMapped]
    public bool IsActive => !IsRevoked && !IsExpired;
}