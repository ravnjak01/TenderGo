using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Entities
{
    public class Location
    {
        public int Id { get; set; }

        public string Name { get; set; } = string.Empty; 
        public string Country { get; set; } = string.Empty;
        public string? Region { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
