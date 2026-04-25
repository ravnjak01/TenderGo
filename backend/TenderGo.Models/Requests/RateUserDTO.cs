using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class RateUserDTO
    {
        public string RatedByUserId { get; set; }
        public string RatedUserId { get; set; } = null!;
        public int TenderId { get; set; }
        public int Score { get; set; }
        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
