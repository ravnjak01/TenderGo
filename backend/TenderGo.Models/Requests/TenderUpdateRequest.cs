using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace TenderGo.Models.Requests
{
    public class TenderUpdateRequest
    {
        [Required]
        [MaxLength(200, ErrorMessage = "Title cannot exceed 200 characters.")]
        public string Title { get; set; } = string.Empty;

        [MaxLength(1000, ErrorMessage = "Description cannot exceed 1000 characters.")]
        public string? Description { get; set; }

        [Range(0, double.MaxValue, ErrorMessage = "MaxBudget must be a positive number.")]
        public decimal MaxBudget { get; set; }

        [Required]
        public DateTime Deadline { get; set; }

        [Required]
        public int CategoryId { get; set; }

        [Required]
        public int LocationId { get; set; }

        public List<TenderImageUpdateRequest>? Images { get; set; } = new List<TenderImageUpdateRequest>();
    }

    public class TenderImageUpdateRequest
    {
        [Required]
        public string ImageUrl { get; set; } = string.Empty;
        public string? ImageHash { get; set; }
    }
}