using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
    public class TenderExpiredEvent
    {
        public int TenderId { get; set; }
        public string TenderTitle { get; set; }
        public string OwnerUserId { get; set; }
        public DateTime ExpiredAt { get; set; }
    }
}
