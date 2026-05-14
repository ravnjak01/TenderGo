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
using TenderGo.Services.Services;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.StateMachines.TenderStates
{
    public class ClosedTenderState : BaseState
    {

        public ClosedTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper, ILogger<ClosedTenderState> logger)
            : base(serviceProvider, context, mapper, logger)
        {

        }


        public override async Task<TenderDTO> Award(Tender tender, int bidId)
        {
           

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            if (tender.CreatedByUserId != authService.GetCurrentUserId())
                throw new UserException("You can only award your own tenders");

            var winningBid = tender.Bids.FirstOrDefault(b => b.Id == bidId)
                ?? throw new UserException("Bid not found or does not belong to this tender");

            _logger.LogInformation("Awarding tender {Id} to bid {BidId}", tender.Id, bidId);

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
        public override async Task<TenderDTO> Cancel(int id)
        {
            var tender = await _context.Tenders.FindAsync(id)
                ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });

            tender.Status = TenderStatus.Cancelled;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Tender {Id} cancelled from Closed state by admin", id);
            return _mapper.Map<TenderDTO>(tender);
        }

        public override async Task<List<string>> AllowedActions(Tender entity)
        {
            var list = await base.AllowedActions(entity);

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            bool isAdmin = authService.IsInRole(AppRoles.Admin);

            if (isAdmin)
            {
                list.Add("Cancel");
            }

            if (entity.Bids != null && entity.Bids.Any(b => b.Status == ApplicationStatus.Pending))
            {
                list.Add("Award"); 
            }

            return list;
        }

    }
}
