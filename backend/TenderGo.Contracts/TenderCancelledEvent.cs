using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Contracts
{
    public class TenderCancelledEvent
    {
        public int TenderId { get; set; }
        public string TenderTitle { get; set; } = string.Empty;
        public string CancelledByUserId { get; set; }
        public string Reason { get; set; }
        public List<string> AffectedUserIds { get; set; } = new();
    }
}
