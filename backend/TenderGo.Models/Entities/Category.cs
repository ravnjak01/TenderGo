using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Entities
{
    public class Category
    {
        public int Id { get; set; }
        [Required]
        public string Name { get; set; } = string.Empty;

        [Required]
        public bool IsActive { get; set; } = true;
        [MaxLength(500)]
        public string Description { get; set; }= string.Empty;

    }
}
