using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
        public class PagedResult<T>
        {
            public List<T> Result { get; set; } = new List<T>();
            public int TotalCount { get; set; }
            public int Page { get; set; }
            public int PageSize { get; set; }
        }
}
