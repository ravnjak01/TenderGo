using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
    public class BidCreatedEvent
    {
        public int TenderId { get; set; }
        public decimal OfferedPrice { get; set; }
        public string OwnerUserId { get; set; }
    }
}
