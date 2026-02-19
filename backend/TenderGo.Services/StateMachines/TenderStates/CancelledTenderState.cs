using AutoMapper;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;

namespace TenderGo.Services.StateMachines.TenderStates
{
    public class CancelledTenderState:BaseState
    {
        public CancelledTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper,ILogger<CancelledTenderState>logger)
            :base(serviceProvider, context, mapper, logger)
        {
            
        }
    }
}
