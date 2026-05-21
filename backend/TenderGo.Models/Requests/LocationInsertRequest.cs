using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class LocationInsertRequest
    {
        public string Country { get; set; }
        public string Name { get; set; }
        public string? Region { get; set; }



    }
}
