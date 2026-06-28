using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Entities
{
    public class TenderImage : BaseEntity
    {
        public int Id { get; set; }
        [Required]
        public string ImageUrl { get; set; } = string.Empty;
        public bool IsPrimary { get; set; } = false;
        [Required]
        public string ImageHash { get; set; } = string.Empty;
        public int TenderId { get; set; }
        public virtual Tender Tender { get; set; } = null!;
    }
}