using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Entities
{
    public class RefreshToken:BaseEntity
    {
        public int Id { get; set; }
        [Required]
        [MaxLength(200)]
        public string Token { get; set; }

        [Required]
        public string UserId { get; set; }
        [ForeignKey("UserId")]
        public ApplicationUser User { get; set; }

        public DateTime Expires { get; set; }

        [NotMapped]
        public bool IsExpired => DateTime.UtcNow >= Expires;

        public bool IsRevoked { get; set; }
        public DateTime? RevokedAt { get; set; }

        [NotMapped]
        public bool IsActive => !IsRevoked && !IsExpired;
    }
}
