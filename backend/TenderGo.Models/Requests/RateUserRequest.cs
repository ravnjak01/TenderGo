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
        public string RatedByUserId { get; set; }
        [Required]
        public string RatedUserId { get; set; } = null!;
        [Required]
        public int TenderId { get; set; }
        [Required]
        public int Score { get; set; }
        public string? Comment { get; set; }
        [Required]
        public DateTime CreatedAt { get; set; }
    }
}
