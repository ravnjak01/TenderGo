using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.ENUMs;

namespace TenderGo.Models.Entities
{
    public class Bid:BaseEntity
    {
        public int Id { get; set; }
        public int TenderId { get; set; }
        public Tender Tender { get; set; }= null!;

        public string SubmittedByUserId { get; set; }
        public ApplicationUser SubmittedByUser { get; set; } = null!;

        [Range(0, double.MaxValue, ErrorMessage = "OfferedPrice must be a positive number.")]
        public decimal OfferedPrice { get; set; }
        public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
        public ApplicationStatus Status { get; set; } = ApplicationStatus.Pending;
        public string? DeliveryNote { get; set; }
    }
}
