using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.Entities;

namespace TenderGo.Models.Entities
{
    public class Rating
    {
        public int Id { get; set; }

        public string RatedByUserId { get; set; } = null!;
        public virtual ApplicationUser RatedByUser { get; set; } = null!;

        public string RatedUserId { get; set; } = null!;
        public virtual ApplicationUser RatedUser { get; set; } = null!;

        public int TenderId { get; set; }
        public virtual Tender Tender { get; set; } = null!;

        [Range(1, 5)]
        public int Score { get; set; }

        [MaxLength(500)]
        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
