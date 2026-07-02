using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class PagedSearchRequest
    {
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 3;
    }
}
