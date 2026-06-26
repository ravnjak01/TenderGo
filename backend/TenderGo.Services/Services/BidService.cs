using AutoMapper;
using AutoMapper.QueryableExtensions;
using Microsoft.AspNetCore.Http;
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
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;
using TenderGo.Services.StateMachines.BidStates;

namespace TenderGo.Services.Services
{
   public class BidService : BaseService<BidDTO, Bid, BidInsertRequest, BidDTO>, IBidService
    {

        private readonly IAuthService _authService;
        protected readonly ILogger<BidService> _logger;
        protected readonly IServiceProvider _serviceProvider;
        public BidService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor,IAuthService authService, ILogger<BidService> logger, IServiceProvider serviceProvider) : base(context, mapper, httpContextAccessor)
        {
            _authService = authService;
            _logger = logger;
            _serviceProvider = serviceProvider;
        }


        public async Task<List<BidDTO>> GetBidsByUser(string userId)
        {
            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (userId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();
            }

            var bids = await _context.Bids
                .Where(x => x.SubmittedByUserId == userId)
                .ProjectTo<BidDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            var tenderIds = bids.Select(b => b.TenderId).ToList();

            var ratedPairs = await _context.Ratings
                .Where(r =>
                    r.RatedByUserId == currentUserId &&
                    tenderIds.Contains(r.TenderId))
                .Select(r => new
                {
                    r.TenderId,
                    r.RatedUserId
                })
                .ToListAsync();

            foreach (var bid in bids)
            {
                bid.AlreadyRated = ratedPairs.Any(r =>
                    r.TenderId == bid.TenderId &&
                    r.RatedUserId == bid.TenderCreatedByUserId);
            }

            return bids;
        }

        public override async Task<BidDTO> Insert(BidInsertRequest request)
{
    try
    {
        var currentUserId = _authService.GetCurrentUserId();
        var tender = await _context.Tenders.FindAsync(request.TenderId)
              ?? throw new UserException("Tender not found");

        if (currentUserId == tender.CreatedByUserId)
        {
            throw new UserException("OWNER_CANNOT_BID");
        }

        _logger.LogInformation("Attempting to create a new bid for tender {TenderId} by user {UserId}", request.TenderId, currentUserId);

        if (request.DeliveryDays <= 0)
        {
            throw new UserException("Delivery days must be greater than 0");
        }

        var existingPendingBid = await _context.Bids
            .FirstOrDefaultAsync(b => b.TenderId == request.TenderId 
                                   && b.SubmittedByUserId == currentUserId 
                                   && b.Status == ApplicationStatus.Pending);

        var totalAttempts = await _context.Bids
            .CountAsync(b => b.TenderId == request.TenderId 
                          && b.SubmittedByUserId == currentUserId);

        if (totalAttempts >= 3)
        {
            throw new UserException("MAX_BID_ATTEMPTS_EXCEEDED");
        }

        if (existingPendingBid != null)
        {
            existingPendingBid.Status = ApplicationStatus.Cancelled;
            
            _context.Bids.Update(existingPendingBid);
            
            _logger.LogInformation("Cancelling previous pending bid {BidId} for tender {TenderId} by user {UserId}", existingPendingBid.Id, request.TenderId, currentUserId);
        }

        var state = CreateState(ApplicationStatus.Pending, tender.Status);

  
        return await state.Insert(request);
    }
    catch (UserException ex)
    {
        _logger.LogWarning(ex, "User error while creating bid for tender {TenderId}: {Message}", request.TenderId, ex.Message);
        throw;
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Unexpected error while creating bid for tender {TenderId}", request.TenderId);
        throw new UserException("An unexpected error occurred while creating the bid.");
    }
}
   
        public async Task<BidDTO> Withdraw(int id)
        {
            var bid = await _context.Bids.Include(b => b.Tender).FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new UserException("Bid not found");

            var currentUserId = _authService.GetCurrentUserId();
            if (bid.SubmittedByUserId != currentUserId)
            {
                throw new ForbiddenException();
            }


            _logger.LogInformation("Attempting to withdraw bid {BidId}", id);

            var state = CreateState(bid.Status, bid.Tender.Status);

            return await state.Withdraw(id);
        }

        public async Task<List<BidDTO>> GetBidsForTender(int tenderId)
        {
            var tender = await _context.Tenders.FindAsync(tenderId)
                      ?? throw new NotFoundException("Tender", tenderId);

            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (tender.CreatedByUserId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();
            }

            // 1. Prvo povuci sve ponude u listu
            var bids = await _context.Bids
                .Where(b => b.TenderId == tenderId)
                .OrderByDescending(b => b.SubmittedAt)
                .ProjectTo<BidDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            // 2. Izvuci iz baze sve ocjene koje je trenutni korisnik (vlasnik tendera) 
            //    već dao na OVOM konkretnom tenderu
            var ratedUserIds = await _context.Ratings
                .Where(r => r.RatedByUserId == currentUserId && r.TenderId == tenderId)
                .Select(r => r.RatedUserId)
                .ToListAsync();

            // 3. Prođi kroz sve ponude i postavi ispravan AlreadyRated status
            foreach (var bid in bids)
            {
                // Ako je ID korisnika koji je poslao ponudu u listi već ocijenjenih -> true
                bid.AlreadyRated = ratedUserIds.Contains(bid.SubmittedByUserId);
            }

            return bids;
        }

        public async Task<List<string>> AllowedActions(int id)
        {
            var entity= await _context.Bids.Include(b => b.Tender).FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new UserException("Bid not found");

            var state = CreateState(entity.Status, entity.Tender.Status);

            return await state.AllowedActions(entity);
        }

        public async Task<BidDTO> Cancel(int id)
        {
            var entity = await _context.Bids.Include(b => b.Tender).FirstOrDefaultAsync(b => b.Id == id)
                 ?? throw new NotFoundException("Bid not found", new { Entity = "Bid", Id = id });

            var state = CreateState(entity.Status,entity.Tender.Status);
            var result = await state.Cancel(id);

            await _context.SaveChangesAsync();

            return result;
        }


        public BaseBidState CreateState(ApplicationStatus bidStatus, TenderStatus tenderStatus)
        {
            if (tenderStatus == TenderStatus.Cancelled)
            {
                return _serviceProvider.GetRequiredService<FinalBidState>();
            }

            return bidStatus switch
            {
                ApplicationStatus.Pending => _serviceProvider.GetRequiredService<PendingBidState>(),
                ApplicationStatus.Withdrawn => _serviceProvider.GetRequiredService<FinalBidState>(),
                ApplicationStatus.Accepted => _serviceProvider.GetRequiredService<FinalBidState>(),
                ApplicationStatus.Rejected => _serviceProvider.GetRequiredService<FinalBidState>(),
                ApplicationStatus.Cancelled => _serviceProvider.GetRequiredService<FinalBidState>(),

                _ => _serviceProvider.GetRequiredService<PendingBidState>()
            };
        }

    }
}
