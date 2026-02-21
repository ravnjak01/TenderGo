using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.StateMachines.TenderStates
{
    public class ClosedTenderState : BaseState
    {

        public ClosedTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper, ILogger<ClosedTenderState> logger)
            : base(serviceProvider, context, mapper, logger)
        {

        }


        public override async Task<TenderDTO> Award(int id, int bidId)
        {
            
            var tender = await _context.Tenders
                .Include(t => t.Bids)
                .FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new UserException("Tender not found");

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            if (tender.CreatedByUserId != authService.GetCurrentUserId())
                throw new UserException("You can only award your own tenders");

            var winningBid = tender.Bids.FirstOrDefault(b => b.Id == bidId)
                ?? throw new UserException("Bid not found or does not belong to this tender");

            _logger.LogInformation("Awarding tender {Id} to bid {BidId}", id, bidId);

            tender.Status = TenderStatus.Awarded;
            tender.WinningBidId = bidId;

            winningBid.Status = ApplicationStatus.Accepted;

            foreach (var otherBid in tender.Bids.Where(b => b.Id != bidId))
            {
                otherBid.Status = ApplicationStatus.Rejected;
            }

            await _context.SaveChangesAsync();

            return _mapper.Map<TenderDTO>(tender);
        }

        public override async Task<List<string>> AllowedActions(Tender entity)
        {
            var list = await base.AllowedActions(entity);

            if (entity.Bids != null && entity.Bids.Any(b => b.Status == ApplicationStatus.Pending))
            {
                list.Add("Award");
            }

            list.Add("Cancel");
            return list;
        }

    }
}
