using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.StateMachines.TenderStates
{
    public class AwardedTenderState : BaseState
    {
        public AwardedTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper, ILogger<AwardedTenderState> logger)
            : base(serviceProvider, context, mapper, logger)
        {
        }

        public override bool CanRate()
        {
            return true;
        }

        public override async Task<List<string>> AllowedActions(Tender entity)
        {
            var list = await base.AllowedActions(entity);
            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            var currentUserId = authService.GetCurrentUserId();

            var winningBid = entity.Bids
                .FirstOrDefault(b => b.Id == entity.WinningBidId) ??
                entity.Bids.FirstOrDefault(b => b.Status == ApplicationStatus.Accepted);

            if (winningBid == null)
            {
                return list;
            }

            var ratedUserId = entity.CreatedByUserId == currentUserId
                ? winningBid.SubmittedByUserId
                : winningBid.SubmittedByUserId == currentUserId
                    ? entity.CreatedByUserId
                    : null;

            if (ratedUserId == null)
            {
                return list;
            }

            var alreadyRated = await _context.Ratings.AnyAsync(r =>
                r.TenderId == entity.Id &&
                r.RatedByUserId == currentUserId &&
                r.RatedUserId == ratedUserId);

            if (!alreadyRated)
            {
                list.Add("Rate");
            }

            return list;
        }
    }
}
