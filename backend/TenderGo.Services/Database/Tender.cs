using System;
using System.Collections.Generic;

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
}
