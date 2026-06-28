using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Services.Interfaces
{
    public interface IEmailService
    {
        Task SendResetPasswordEmail(string toEmail, string resetCode, CancellationToken cancellationToken);

    }
}
