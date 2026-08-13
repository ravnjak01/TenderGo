using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Services.Services.Exceptions
{
    public class BaseException:Exception
    {
        public int StatusCode { get; set; }
        public BaseException(string message,int statusCode=404):base(message)
        {
            StatusCode = statusCode;
        }
        public BaseException(string message, Exception innerException, int statusCode = 500)
        : base(message, innerException)
        {
            StatusCode = statusCode;
        }
    }
}
