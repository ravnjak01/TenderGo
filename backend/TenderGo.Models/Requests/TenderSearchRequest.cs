using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class TenderSearchRequest:PagedSearchRequest
    {
        public string? SearchTerm { get; set; }
    }
}
