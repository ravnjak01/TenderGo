using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.ENUMs;

namespace TenderGo.Models.DTOs
{
    public class ActivityDTO
    {
        public DateTime CreatedAt { get; set; }
        public string UserName { get; set; } = string.Empty;
        public ActivityType ActivityType { get; set; }
        public string Action { get; set; } = string.Empty;

        public string? Details { get; set; }
    }
}
