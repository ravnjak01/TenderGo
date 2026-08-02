using AutoMapper;
using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using TenderGo.Api.Database;
using TenderGo.Contracts;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.StateMachines.TenderStates
{
    public class OpenTenderState : BaseState
    {
        private readonly IPubSub _pubSub;


        public OpenTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper, ILogger<OpenTenderState> logger, IPubSub pubSub)
            : base(serviceProvider, context, mapper, logger)
        {
            _pubSub = pubSub;
        }

        public override async Task<TenderDTO> Cancel(int id,TenderCancelRequest request)
        {
            var tender = await _context.Tenders
                .Include(t => t.Bids)
                .FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            var currentUserId = authService.GetCurrentUserId();
            bool isAdmin = authService.IsInRole(AppRoles.Admin);
            if (tender.CreatedByUserId != authService.GetCurrentUserId() && !isAdmin)
                throw new UserException("You can only cancel your own tenders");

            tender.Status = TenderStatus.Cancelled;
            tender.CancellationReason = request.Reason;
            tender.CancelledAt=DateTime.UtcNow;
            tender.CancelledByUserId = currentUserId;

            _logger.LogInformation("Tender with ID {TenderId} has been cancelled while in Open state", id);

            if (tender.Bids != null && tender.Bids.Any())
            {
                foreach (var bid in tender.Bids)
                {
                    bid.Status = ApplicationStatus.Cancelled;
                }
            }


            var affectedUserIds = tender.Bids
                .Where(b => !string.IsNullOrEmpty(b.SubmittedByUserId))
                .Select(b => b.SubmittedByUserId)
                .Distinct()
                .ToList();
            await _context.SaveChangesAsync();


            try
            {
                await _pubSub.PublishAsync(
                    new TenderCancelledEvent
                    {
                        TenderId = tender.Id,
                        TenderTitle = tender.Title,
                        CancelledByUserId = currentUserId,
                        Reason = request.Reason,
                        AffectedUserIds = affectedUserIds 
                    },
                    cfg => cfg.WithTopic("tender_cancelled"));
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Tender {TenderId} cancelled but TenderCancelledEvent was not published", tender.Id);
            }


            return _mapper.Map<TenderDTO>(tender);
        }

        public override async Task<List<string>> AllowedActions(Tender entity)
        {
            var list = await base.AllowedActions(entity);

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            var currentUserId = authService.GetCurrentUserId();

            bool isOwner = entity.CreatedByUserId == currentUserId;
            bool isAdmin = authService.IsInRole(AppRoles.Admin);

            if (!isOwner && !isAdmin)
            {
                var userBids = entity.Bids?
                    .Where(b => b.SubmittedByUserId == currentUserId)
                    .ToList() ?? new List<Bid>();

                bool hasActiveBid = userBids.Any(b => b.Status != ApplicationStatus.Withdrawn);

                bool maxAttemptsReached = userBids.Count >= 3;

                if (!hasActiveBid && !maxAttemptsReached)
                {
                    list.Add("SubmitBid");
                }
            }

            if(isAdmin || isOwner)
            {
                list.Add("Cancel");
            }

            return list;
        }
    }
}
