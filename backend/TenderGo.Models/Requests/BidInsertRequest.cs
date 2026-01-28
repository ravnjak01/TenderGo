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
        public int Id { get; set; }
        public decimal Price { get; set; }
        public int TenderId { get; set; }
        [StringLength(500)]
        public string? Note { get; set; }
        public int UserId { get; set; }
    }
}
