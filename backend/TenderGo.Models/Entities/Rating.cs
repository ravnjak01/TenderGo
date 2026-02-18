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
        public string RatedByUserId { get; set; }
        public ApplicationUser RatedByUser { get; set; }

        public string RatedUserId { get; set; }
        public ApplicationUser RatedUser { get; set; }

        public int TenderId { get; set; }
        public Tender Tender { get; set; }

        [Range(1, 5)]
        public int Score { get; set; }

        public string? Commit { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
