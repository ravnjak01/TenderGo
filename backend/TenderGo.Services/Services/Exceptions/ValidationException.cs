using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Services.Services.Exceptions
{
    public class ValidationException:BaseException
    {
        public IDictionary<string, string[]> Errors { get; }

        public ValidationException()
            : base("One or more validation errors occurred.", 400)
        {
            Errors = new Dictionary<string, string[]>();
        }
        public ValidationException(IDictionary<string, string[]> errors)
            : this()
        {
            Errors = errors;
        }
    }
}
