using AutoMapper;
using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Contracts;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.StateMachines.BidStates
{
    public class PendingBidState : BaseBidState
    {
        private readonly IPubSub _pubSub;
        private readonly ILogger<PendingBidState> _logger;
        private readonly IAuthService _authService;
        public PendingBidState(
            IServiceProvider serviceProvider,
            TenderGoContext context,
            IMapper mapper,
            IPubSub pubSub,
            ILogger<PendingBidState> logger,
            IAuthService authService)
            : base(serviceProvider, context, mapper)
        {
            _pubSub = pubSub;
            _logger = logger;
            _authService = authService;
        }

        public override async Task<BidDTO> Insert(BidInsertRequest request)
        {
            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            var currentUserId = authService.GetCurrentUserId();

            var alreadyResponded = await _context.Bids
                .AnyAsync(b => b.TenderId == request.TenderId && b.SubmittedByUserId == currentUserId && b.Status != ApplicationStatus.Withdrawn);

            if (alreadyResponded)
            {
                throw new UserException("You have already submitted a bid for this tender. Withdraw it first if you wish to submit a new one.");
            }

            var tender = await _context.Tenders.FindAsync(request.TenderId);
            if (tender == null || tender.Status != TenderStatus.Open)
            {
                throw new UserException("Tender is not open for new bids.");
            }

            var entity = _mapper.Map<Bid>(request);
            entity.Status = ApplicationStatus.Pending;
            entity.SubmittedAt = DateTime.UtcNow;
            entity.SubmittedByUserId = currentUserId;

            _context.Bids.Add(entity);
            await _context.SaveChangesAsync();

            var savedBid = await _context.Bids
                .Include(b => b.Tender)
                .Include(b => b.SubmittedByUser)
                .FirstAsync(b => b.Id == entity.Id);


            //try
            //{
            //    await _pubSub.PublishAsync(
            //        new BidCreatedEvent
            //        {
            //            TenderId = entity.TenderId,
            //            OwnerUserId = tender.CreatedByUserId,
            //            OfferedPrice = entity.OfferedPrice,
            //            TenderTitle = tender.Title
            //        },
            //        cfg => cfg.WithTopic("bid_created"));
            //}
            //catch (Exception ex)
            //{
            //    _logger.LogWarning(
            //        ex,
            //        "Bid saved but BidCreatedEvent was not published for tender {TenderId}",
            //        entity.TenderId);

            //}

            return _mapper.Map<BidDTO>(savedBid);
        }

        public override async Task<BidDTO> Withdraw(int id)
        {
            var bid = await _context.Bids
                .Include(b => b.Tender)
                .FirstOrDefaultAsync(b => b.Id == id)
                 ?? throw new NotFoundException("Bid not found", new { Bid = "Bid", Id = id });

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            if (bid.SubmittedByUserId != authService.GetCurrentUserId())
            {
                throw new UserException("You can only withdraw your own bids.");
            }

            if (bid.Tender.Status != TenderStatus.Open)
                throw new UserException("Tender is no longer open for changes.");

            bid.Status = ApplicationStatus.Withdrawn;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Bid {BidId} has been withdrawn by user.", id);
            return _mapper.Map<BidDTO>(bid);
        }

      

        public override async Task<List<string>> AllowedActions(Bid entity)
        {
            var list = await base.AllowedActions(entity);
            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            var currentUserId = authService.GetCurrentUserId();

            bool isBidOwner = entity.SubmittedByUserId == currentUserId;

            if (isBidOwner)
            {
                list.Add("Withdraw");
            }

            return list;
        }
    }
}
