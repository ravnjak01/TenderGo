using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Entities
{
    public abstract class BaseEntity
    {
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public string? CreatedByUserId { get; set; } 
        public DateTime? UpdatedAt { get; set; }
        public string? UpdatedByUserId { get; set; }
        public bool IsDeleted { get; set; } = false;
    }
}
