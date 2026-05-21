using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
    public class TenderAwardedEvent
    {
        public int TenderId { get; set; }
        public string TenderTitle { get; set; }
        public string Message { get; set; }
        public string WinnerUserId { get; set; }
        public List<string> OtherUserIds { get; set; }
    }
}
