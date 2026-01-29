using System;
using System.Collections.Generic;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;

namespace TenderGo.Api.Database;

public partial class Tender
{
    public int Id { get; set; }

    public string Title { get; set; } = null!;

    public string Description { get; set; } = null!;

    public decimal MaxBudget { get; set; }

    public DateTime Deadline { get; set; }

    public DateTime? CreatedAt { get; set; }

    public TenderStatus Status { get; set; }

    public string CreatedByUserId { get; set; }
    public virtual ApplicationUser CreatedByUser { get; set; }
    public virtual ICollection<TenderApplication> Applicants { get; set; }

    public int CategoryId { get; set; }
    public virtual Category  Category { get; set; }
}
