using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Entities
{
    public class TenderImage:BaseEntity
    {

        public int Id { get; set; }

        [Required]
        public string ImageUrl { get; set; } = null!;
        
        public bool IsPrimary { get; set; } = false;
        public string ImageHash { get; set; }
        public int TenderId { get; set; }
        public virtual Tender Tender { get; set; } = null!;

    }
}
