using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class RateUserRequest
    {
        [Required]
        public string RatedUserId { get; set; } = null!;
        public int TenderId { get; set; }
        [Range(1, 5)]

        public int Score { get; set; }
        public string? Comment { get; set; }
      
    }
}
