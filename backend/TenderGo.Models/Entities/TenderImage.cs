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
        [Required]
        public bool IsPrimary { get; set; } = false;
        [Required]
        public string ImageHash { get; set; } = string.Empty;
        [Required]
        public int TenderId { get; set; }
        [Required]
        public virtual Tender Tender { get; set; } = null!;
    }
}