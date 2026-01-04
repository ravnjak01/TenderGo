using System;
using System.Collections.Generic;
using TenderGo.Models.Entities;

namespace TenderGo.Api.Database;

public partial class Tender
{
    public int Id { get; set; }

    public string Title { get; set; } = null!;

    public string Description { get; set; } = null!;

    public decimal MaxBudget { get; set; }

    public DateTime Deadline { get; set; }

    public DateTime? CreatedAt { get; set; }

    public int Status { get; set; }

    public string? UserId { get; set; }

    public int CategoryId { get; set; }
    public virtual Category  Category { get; set; }
}
