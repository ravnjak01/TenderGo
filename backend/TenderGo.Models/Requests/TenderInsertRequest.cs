using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace TenderGo.Models.Requests
{
    public class TenderInsertRequest
    {
        [Required(ErrorMessage = "Title is required.")]
        [MaxLength(200, ErrorMessage = "Title cannot exceed 200 characters.")]
        public string Title { get; set; } = string.Empty;

        [Required(ErrorMessage = "Max budget is required.")]
        [Range(0.01, double.MaxValue, ErrorMessage = "MaxBudget must be a positive number greater than 0.")]
        public decimal MaxBudget { get; set; }

        [Required(ErrorMessage = "Location is required.")]
        public int LocationId { get; set; }

        [MaxLength(1000, ErrorMessage = "Description cannot exceed 1000 characters.")]
        public string? Description { get; set; }

        [Required(ErrorMessage = "Category is required.")]
        public int CategoryId { get; set; }

        [Required(ErrorMessage = "Deadline is required.")]
        public DateTime Deadline { get; set; }
        public List<byte[]>? ImageBytes { get; set; } = new();
    }
}