using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.ENUMs;

namespace TenderGo.Models.Entities
{
    public class TenderApplication
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public virtual ApplicationUser User { get; set; }
        public DateTime AppliedAt { get; set; }
        public int TenderId { get; set; }
        public virtual Tender Tender { get; set; }
        public ApplicationStatus Status { get; set; }
    }
}
