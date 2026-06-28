using System.ComponentModel.DataAnnotations;

namespace TenderGo.Models.Entities
{
    public class Rating
    {
        public int Id { get; set; }

        [Required]
        public string RatedByUserId { get; set; } = string.Empty;

        public virtual ApplicationUser RatedByUser { get; set; } = null!;

        [Required]
        public string RatedUserId { get; set; } = string.Empty;

        public virtual ApplicationUser RatedUser { get; set; } = null!;

        public int TenderId { get; set; }

        public virtual Tender Tender { get; set; } = null!;

        [Range(1, 5)]
        public int Score { get; set; }

        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}