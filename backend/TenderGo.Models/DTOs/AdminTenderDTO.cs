using System;
using TenderGo.Models.ENUMs;

namespace TenderGo.Models.DTOs
{
    public class AdminTenderDTO
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string CreatedByUserFullName { get; set; } = string.Empty;
        public DateTime Deadline { get; set; }
        public decimal MaxBudget { get; set; }
        public TenderStatus  Status { get; set; }
    }
}
