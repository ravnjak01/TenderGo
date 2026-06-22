using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
    public class AdminReportOverviewDTO
    {
        public decimal TotalTenderValue { get; set; }
        public double TenderRealizationPercentage { get; set; }
        public int CancelledTenderCount { get; set; }
    }
}
