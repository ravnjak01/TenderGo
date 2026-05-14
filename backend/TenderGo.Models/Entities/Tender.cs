using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using TenderGo.Models.ENUMs;

namespace TenderGo.Models.Entities;

public class Tender : BaseEntity
{
    public int Id { get; set; }
    [Required]
    [MaxLength(200, ErrorMessage = "Title cannot exceed 200 characters.")]
    public string Title { get; set; } = string.Empty;
    [MaxLength(1000, ErrorMessage = "Description cannot exceed 1000 characters.")]
    public string? Description { get; set; }
    [Required]
    [Column(TypeName = "decimal(18,2)")]
    [Range(0, double.MaxValue, ErrorMessage = "MaxBudget must be a positive number.")]
    public decimal MaxBudget { get; set; }
    [Required]
    public DateTime Deadline { get; set; }
    [Required]
    public TenderStatus Status { get; set; }
    [Required]
    public string CreatedByUserId { get; set; } = string.Empty;
    [Required]
    public virtual ApplicationUser CreatedByUser { get; set; } = null!;
    public DateTime? PostedAt { get; set; }
    [Required]
    public int CategoryId { get; set; }
    [Required]
    public virtual Category Category { get; set; } = null!;
    public int? WinningBidId { get; set; }
    public virtual Bid? WinningBid { get; set; }
    [Required]
    public bool IsEdited { get; set; } = false;
    [Required]
    public string LocationName { get; set; } = string.Empty;
    [Required]
    public string Country { get; set; } = string.Empty;
    public virtual ICollection<Bid> Bids { get; set; } = new List<Bid>();
    public virtual ICollection<TenderImage> Images { get; set; } = new List<TenderImage>();
}