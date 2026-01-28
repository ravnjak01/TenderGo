using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;

namespace TenderGo.Models.Entities
{
    public class Bid
    {
        public int Id { get; set; }
        public int TenderId { get; set; }
        public Tender Tender { get; set; }

        public string SubmittedByUserId { get; set; }
        public decimal OfferedPrice { get; set; }
        public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
    }
}
