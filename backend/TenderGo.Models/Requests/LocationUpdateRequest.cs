using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class LocationUpdateRequest
    {
        [MaxLength(150, ErrorMessage = "Name cannot exceed 150 characters.")]
        public string? Name { get; set; } 

        [MaxLength(100, ErrorMessage = "Country cannot exceed 100 characters.")]
        public string? Country { get; set; } 

        [MaxLength(100, ErrorMessage = "Region cannot exceed 100 characters.")]
        public string? Region { get; set; } 
    }
}
