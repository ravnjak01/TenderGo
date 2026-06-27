using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
    public class CategoryStatsDTO
    {
        public int CategoryId { get; set; }

        public string CategoryName { get; set; } = string.Empty;

        public int TenderCount { get; set; }
        public string Description { get; set; }
        public bool IsActive { get; set; }
    }
}
