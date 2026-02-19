using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;

namespace TenderGo.Services.StateMachines.BidStates
{
    public class FinalBidState:BaseBidState
    {
        public FinalBidState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper)
        : base(serviceProvider, context, mapper) { }
    }
}
