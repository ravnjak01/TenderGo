using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class ForgotPasswordRequest
    {
        [Required]  
        public string Email { get; set; } = string.Empty;
    }
}
