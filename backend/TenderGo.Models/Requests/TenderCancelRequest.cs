using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class TenderCancelRequest
    {
        [Required(ErrorMessage = "Cancellation reason is required.")]
        [StringLength(500, MinimumLength = 5, ErrorMessage = "Reason must be between 5 and 500 characters.")]
        public string Reason { get; set; } = null!;
    }
}
