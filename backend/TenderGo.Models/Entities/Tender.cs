using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;

namespace TenderGo.Models.Entities;

public partial class Tender
{
    public int Id { get; set; }

    public string Title { get; set; } = null!;

    public string Description { get; set; } = null!;

    [Range(0, double.MaxValue, ErrorMessage = "MaxBudget must be a positive number.")]
    public decimal MaxBudget { get; set; }

    public DateTime Deadline { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public TenderStatus Status { get; set; } 

    public string CreatedByUserId { get; set; }
    public virtual ApplicationUser CreatedByUser { get; set; }

    public int CategoryId { get; set; }
    public virtual Category  Category { get; set; }=null!;

    public int? WinningBidId { get; set; }
    public virtual Bid? WinningBid { get; set; }

    public bool IsEdited { get; set; } = false;


    public virtual ICollection<Bid> Bids { get; set; } = new List<Bid>();
    public virtual ICollection<TenderImage> Images { get; set; } = new List<TenderImage>();
}
