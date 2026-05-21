using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using TenderGo.Models.ENUMs;

namespace TenderGo.Models.Entities
{
    public class Bid : BaseEntity
    {
        public int Id { get; set; }
        [Required]
        public int TenderId { get; set; }
        [Required]
        public Tender Tender { get; set; } = null!;
        [Required]
        public string SubmittedByUserId { get; set; } = string.Empty;
        [Required]
        public ApplicationUser SubmittedByUser { get; set; } = null!;
        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "OfferedPrice must be a positive number.")]
        public decimal OfferedPrice { get; set; }
        [Required]
        public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
        [Required]
        public ApplicationStatus Status { get; set; } = ApplicationStatus.Pending;
        public string? Proposal { get; set; }
        [Required]
        public int DeliveryDays { get; set; }
    }
}