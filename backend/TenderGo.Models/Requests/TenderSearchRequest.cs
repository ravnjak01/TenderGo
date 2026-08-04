using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class TenderSearchRequest : PagedSearchRequest
    {
        public string? SearchTerm { get; set; }
        public int? CategoryId { get; set; }
        public int? LocationId { get; set; }
        public string? Country { get; set; }
        public string? Region { get; set; }
    }
}
