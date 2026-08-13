using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Services.Services.Exceptions
{
    public class InternalServerException : BaseException
    {
        public InternalServerException(string message = "An internal error occurred on the server.")
            : base(message, 500) { }
    }
}
