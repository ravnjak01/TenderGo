using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Services.Services.Exceptions
{
    public class UnauthorizedException:BaseException
    {
        public UnauthorizedException(string message = "You are not authorized. Please log in.") : base(message, 401) { }
    }
}
