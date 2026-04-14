using AutoMapper;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.StateMachines.TenderStates
{
    public class AwardedTenderState:BaseState
    {
        public AwardedTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper,ILogger<AwardedTenderState> logger)
            :base(serviceProvider, context, mapper, logger)
        {
            
        }

    }
}
