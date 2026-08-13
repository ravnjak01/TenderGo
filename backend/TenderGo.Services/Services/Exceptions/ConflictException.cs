using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Services.Services.Exceptions
{
    public class ConflictException : BaseException
    {
        public ConflictException(string message = "A conflict occurred with the current state of the resource.")
            : base(message, 409) { }

        public ConflictException(string entityName, object key)
            : base($"{entityName} with key ({key}) already exists.", 409) { }
    }
}
