using AutoMapper;
using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Contracts;
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
        private readonly IPubSub _pubSub;
        public ClosedTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper, ILogger<ClosedTenderState> logger,IPubSub pubSub)
            : base(serviceProvider, context, mapper, logger)
        {
            _pubSub = pubSub;
        }


        public override async Task<TenderDTO> Award(Tender tender, int bidId)
        {

            if (tender.Bids == null || !tender.Bids.Any())
                _logger.LogWarning("Tender {Id} has no bids loaded — OtherUserIds will be empty", tender.Id);

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            if (tender.CreatedByUserId != authService.GetCurrentUserId())
                throw new UserException("You can only award your own tenders");

            var winningBid = tender.Bids.FirstOrDefault(b => b.Id == bidId)
                ?? throw new UserException("Bid not found or does not belong to this tender");

            _logger.LogInformation("Awarding tender {Id} to bid {BidId}", tender.Id, bidId);

            tender.Status = TenderStatus.Awarded;
            tender.WinningBidId = bidId;
            winningBid.Status = ApplicationStatus.Accepted;

            var otherPendingBids = tender.Bids
            .Where(b => b.Id != bidId && b.Status == ApplicationStatus.Pending)
            .ToList();

            foreach (var otherBid in otherPendingBids)
            {
                otherBid.Status = ApplicationStatus.Rejected;
            }

            await _context.SaveChangesAsync();

            try
            {
                await _pubSub.PublishAsync(
                    new TenderAwardedEvent
                    {
                        TenderId = tender.Id,
                        TenderTitle = tender.Title,
                        WinnerUserId = winningBid.SubmittedByUserId,
                        OtherUserIds = otherPendingBids
                            .Select(b => b.SubmittedByUserId)
                            .ToList()
                    },
                    cfg => cfg.WithTopic("tender_awarded"));
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Tender {TenderId} awarded but TenderAwardedEvent was not published",
                    tender.Id);
            }

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
