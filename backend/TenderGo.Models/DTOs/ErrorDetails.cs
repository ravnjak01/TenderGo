using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
    public class ErrorDetails
    {
        public int StatusCode { get; set; }
        public string Message { get; set; }
        public string? Type { get; set; } 

        public override string ToString() => System.Text.Json.JsonSerializer.Serialize(this);
    }
}
