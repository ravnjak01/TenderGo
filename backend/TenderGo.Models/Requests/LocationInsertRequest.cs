using System.ComponentModel.DataAnnotations;

namespace TenderGo.Models.Requests
{
    public class LocationInsertRequest
    {
        [Required]
        [StringLength(100)]
        public string Country { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(100)]
        public string? Region { get; set; }
    }
}