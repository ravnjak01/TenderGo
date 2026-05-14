using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.Entities;

namespace TenderGo.Models.Requests
{
    public class TenderInsertRequest
    {
        [Required]
        public string Title { get; set; }
        [Required]
        public decimal MaxBudget { get; set; }
        [Required]
        public string LocationName { get; set; }
        public string? Description { get; set; }
        [Required]
        public int CategoryId { get; set; }
        [Required]
        public DateTime Deadline { get; set; }
        public List<byte[]>? ImageBytes { get; set; } = new();

    }
}
