using AutoMapper;
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



        protected override IQueryable<Bid> AddIncludes(IQueryable<Bid> query)
        {
            return query
                .Include(b => b.Tender)             
                .Include(b => b.SubmittedByUser);   
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
                .ToListAsync();

            return _mapper.Map<List<BidDTO>>(bids);
        }

        public override async Task<BidDTO> Insert(BidInsertRequest request)
        {

            try
            {

            var currentUserId = _authService.GetCurrentUserId();
            var tender = await _context.Tenders.FindAsync(request.TenderId)
                  ?? throw new UserException("Tender not found");

            if(currentUserId == tender.CreatedByUserId)
            {
                throw new UserException("OWNER_CANNOT_BID");
            }

            _logger.LogInformation("Attempting to create a new bid for tender {TenderId} by user {UserId}", request.TenderId, _authService.GetCurrentUserId());

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
                      ?? throw new NotFoundException("Tender",tenderId);

            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (tender.CreatedByUserId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();

            }
            var bids = await _context.Bids
                .Include(b => b.SubmittedByUser)
                .Include(b => b.Tender)
                .Where(b => b.TenderId == tenderId)
                  .OrderByDescending(b => b.SubmittedAt)
                .ToListAsync();

          
            return _mapper.Map<List<BidDTO>>(bids);
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


            return result;
        }


        public BaseBidState CreateState(ApplicationStatus bidStatus, TenderStatus tenderStatus)
        {
            if (tenderStatus != TenderStatus.Open)
            {
                return _serviceProvider.GetRequiredService<FinalBidState>();
            }

            return bidStatus switch
            {
                ApplicationStatus.Pending => _serviceProvider.GetRequiredService<PendingBidState>(),
                ApplicationStatus.Withdrawn => _serviceProvider.GetRequiredService<FinalBidState>(),
                ApplicationStatus.Accepted => _serviceProvider.GetRequiredService<FinalBidState>(),
                ApplicationStatus.Rejected => _serviceProvider.GetRequiredService<FinalBidState>(),
                _ => _serviceProvider.GetRequiredService<PendingBidState>()
            };
        }

    }
}
