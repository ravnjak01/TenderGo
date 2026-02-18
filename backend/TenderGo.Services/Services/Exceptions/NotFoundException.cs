using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Services.Services.Exceptions
{
    public class NotFoundException: BaseException
    {
        public NotFoundException(string entityName, object key)
        : base($"{entityName} with id ({key}) was not found.", 404) { }
    }
}
