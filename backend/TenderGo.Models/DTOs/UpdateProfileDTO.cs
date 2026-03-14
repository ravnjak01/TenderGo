using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.Entities;

namespace TenderGo.Models.DTOs
{
    public class UpdateProfileDTO
    {
        public string? PhoneNumber { get; set; }
        public UpdateAddressDTO? Address { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string? UserName { get; set; }
    }
}
