using System.ComponentModel.DataAnnotations;

namespace TenderGo.Models.Requests

{
    public class ResetPasswordRequest
    {
        [Required]
        public string Email { get; set; }

        [Required]
        public string Token { get; set; }

        [Required]
        [MinLength(8)]
        public string NewPassword { get; set; }
    }
}
