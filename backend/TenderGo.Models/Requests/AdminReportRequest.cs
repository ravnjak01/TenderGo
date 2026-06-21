using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class AdminReportRequest
    {
        public string Type { get; set; } = string.Empty;
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
    }
}
