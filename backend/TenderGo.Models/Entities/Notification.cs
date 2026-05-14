using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Entities
{
    public class Notification
    {
        public int Id { get; set; }
        [Required]
        public string UserId { get; set; }

        public virtual  ApplicationUser User{ get; set; }
        [Required]
        public string Title { get; set; }

        [Required]
        public string Message { get; set; }
        [Required]
        public DateTime CreatedAt { get; set; }
        [Required]
        public bool IsRead { get; set; }
    }
}
