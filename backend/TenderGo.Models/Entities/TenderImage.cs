using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Entities
{
    public class TenderImage
    {

        public int Id { get; set; }

        public string ImageUrl { get; set; } = null!;

        public bool IsPrimary { get; set; } = false;

        public int TenderId { get; set; }
        public virtual Tender Tender { get; set; } = null!;

        public DateTime? CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
