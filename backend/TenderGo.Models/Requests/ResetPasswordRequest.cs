using System.ComponentModel.DataAnnotations;

namespace TenderGo.Models.Requests

{
    public class ResetPasswordRequest
    {
        [Required(ErrorMessage = "Email address is required")]
        [EmailAddress(ErrorMessage = "Invalid email address format")]
        [RegularExpression(@"^[^@\s]+@[^@\s]+\.[^@\s]+$", ErrorMessage = "Email must be in a valid format (e.g. user@example.com)")]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Token { get; set; }

        [Required]
        [MinLength(8)]
        public string NewPassword { get; set; }
    }
}
