using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.ENUMs;

namespace TenderGo.Models.Requests
{
    public class AdminTenderSearchRequest:PagedSearchRequest
    {
        public string? SearchTerm { get; set; }
        public int? CategoryId { get; set; }
        public int? LocationId { get; set; }
        public TenderStatus? Status { get; set; }
    }
}
