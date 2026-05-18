using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class BidInsertRequest
    {
        [Required]
        public decimal Price { get; set; }
        [Required]
        public int TenderId { get; set; }
        [StringLength(500)]
        public string? Note { get; set; }
        [Required]
        public string UserId { get; set; }
    }
}
