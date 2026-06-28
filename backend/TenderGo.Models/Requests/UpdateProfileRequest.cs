using System.ComponentModel.DataAnnotations;
using TenderGo.Models.DTOs;

namespace TenderGo.Models.Requests
{
    public class UpdateProfileRequest
    {
        [MaxLength(100)]
        public string? FirstName { get; set; }

        [MaxLength(100)]
        public string? LastName { get; set; }

        [Phone]
        [MaxLength(30)]
        public string? PhoneNumber { get; set; }

        public UpdateAddressRequest? Address { get; set; }

        public byte[]? ImageBytes { get; set; }
    }
}