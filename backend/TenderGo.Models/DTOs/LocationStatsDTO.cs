using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
    public class LocationStatsDTO
    {
        public string LocationName { get; set; } = string.Empty;
        public int TenderCount { get; set; }
        public int LocationId { get; set; }
        public bool IsActive { get; set; }
    }
}
