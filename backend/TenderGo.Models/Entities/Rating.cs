using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using TenderGo.Models.Entities;

namespace TenderGo.Models.Entities
{
    public class Rating
    {
        public int Id { get; set; }
        [Required]
        public string RatedByUserId { get; set; } = string.Empty;
        [Required]
        public virtual ApplicationUser RatedByUser { get; set; } = null!;
        [Required]
        public string RatedUserId { get; set; } = string.Empty;
        [Required]
        public virtual ApplicationUser RatedUser { get; set; } = null!;
        [Required]
        public int TenderId { get; set; }
        [Required]
        public virtual Tender Tender { get; set; } = null!;
        [Required]
        [Range(1, 5)]
        public int Score { get; set; }
        public string? Comment { get; set; }
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}