using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class BidCreateRequest
    {
        public int TenderId { get; set; }
        public decimal OfferedPrice { get; set; }
    }
}
