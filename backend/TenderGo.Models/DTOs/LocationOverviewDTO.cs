using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
    public class LocationOverviewDTO
    {
        public int TotalLocations { get; set; }
        public int ActiveLocations { get; set; }
        public int InactiveLocations { get; set; }
        public int LocationsWithTenders { get; set; }
    }
}
