using System.ComponentModel.DataAnnotations;
using TenderGo.Models.Entities;

public class TenderBookmark
{
    [Required]
    public string UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public int TenderId { get; set; }
    public Tender Tender { get; set; } = null!;

    public DateTime BookmarkedAt { get; set; } = DateTime.UtcNow;
}