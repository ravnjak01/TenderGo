using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Services.Services.Exceptions
{
    public class ForbiddenException:BaseException
    {

        public ForbiddenException(string message = "You do not have permission to access this resource.")
        : base(message, 403) { }
    }
}
