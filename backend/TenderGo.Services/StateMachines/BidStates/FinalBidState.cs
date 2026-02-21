using AutoMapper;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.StateMachines.BidStates
{
    public class FinalBidState:BaseBidState
    {
        public FinalBidState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper)
        : base(serviceProvider, context, mapper) { }


        public async Task<List<string>>AllowedActions(Bid entity)
        {

            var list = await base.AllowedActions(entity);

            var authService = _serviceProvider.GetRequiredService<IAuthService>();

            var currentUserId = authService.GetCurrentUserId();

            bool isTenderOwner = entity.Tender.CreatedByUserId == currentUserId;

            if (isTenderOwner)
            {
                list.Add("Accept");
            }
            return list;
        }
    }
}
