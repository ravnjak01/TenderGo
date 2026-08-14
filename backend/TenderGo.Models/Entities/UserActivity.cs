using System.ComponentModel.DataAnnotations;
using TenderGo.Models.ENUMs;

namespace TenderGo.Models.Entities;

public class UserActivity
{
    public int Id { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;

    [Required]
    public ActivityRecommendType ActivityType { get; set; } 

    public int? TenderId { get; set; }

    public string? SearchQuery { get; set; }

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public Tender? Tender { get; set; }
}

