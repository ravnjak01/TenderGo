using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using TenderGo.Models.ENUMs;

namespace TenderGo.Models.Entities;

public  class Tender:BaseEntity
{
    public int Id { get; set; }
    [Required]
    [MaxLength(200, ErrorMessage = "Title cannot exceed 200 characters.")]
    public string Title { get; set; } = null!;
    [MaxLength(1000, ErrorMessage = "Description cannot exceed 1000 characters.")]
    public string? Description { get; set; } = null!;


    [Column(TypeName = "decimal(18,2)")]
    [Range(0, double.MaxValue, ErrorMessage = "MaxBudget must be a positive number.")]
    public decimal MaxBudget { get; set; }

    public DateTime Deadline { get; set; }
    public TenderStatus Status { get; set; }

    public string CreatedByUserId { get; set; } = null!;

    public virtual ApplicationUser CreatedByUser { get; set; }

    public DateTime? PostedAt { get; set; }

    public int CategoryId { get; set; }
    public virtual Category  Category { get; set; }=null!;

    public int? WinningBidId { get; set; }
    public virtual Bid? WinningBid { get; set; }

    public bool IsEdited { get; set; } = false;

    public string? LocationName { get; set; } 
    public string? Country { get; set; }

    public virtual ICollection<Bid> Bids { get; set; } = new List<Bid>();
    public virtual ICollection<TenderImage> Images { get; set; } = new List<TenderImage>();

}
