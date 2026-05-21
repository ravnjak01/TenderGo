using System.ComponentModel.DataAnnotations;

namespace TenderGo.Api.Controllers
{
    public class AdminResetPasswordRequest
    {
        [Required]
        [MinLength(8, ErrorMessage = "Password has to be 8 characters minimum.")]
        [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$", ErrorMessage = "Password must contain a capital letter, a small letter, and a number.")]
        public string NewPassword { get; set; }

        [Required]
        [Compare("NewPassword", ErrorMessage = "Passwords do not match.")]
        public string ConfirmPassword { get; set; }
    }
}