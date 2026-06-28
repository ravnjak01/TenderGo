using System.ComponentModel.DataAnnotations;

namespace TenderGo.Models.DTOs
{
    public class UpdateAddressRequest
    {
        [MaxLength(200)]
        public string? Street { get; set; }

        [MaxLength(100)]
        public string? City { get; set; }

        [MaxLength(20)]
        public string? PostalCode { get; set; }

        [MaxLength(100)]
        public string? Country { get; set; }
    }
}