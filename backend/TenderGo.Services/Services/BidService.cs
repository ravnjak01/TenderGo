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
   public class BidService : BaseService<BidDTO, Bid, BidInsertRequest, BidUpdateRequest>, IBidService
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
            var bids = await _context.Bids
                .Where(x => x.SubmittedByUserId == userId)
                .ToListAsync();

            return _mapper.Map<List<BidDTO>>(bids);
        }

        public override async Task<BidDTO> Insert(BidInsertRequest request)
        {

            try
            {

            var tender = await _context.Tenders.FindAsync(request.TenderId)
                  ?? throw new UserException("Tender not found");


            _logger.LogInformation("Attempting to create a new bid for tender {TenderId} by user {UserId}", request.TenderId, _authService.GetCurrentUserId());

            // Kreiramo stanje (ovdje proslijeđujemo početni status Pending i trenutni status tendera)
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
                Console.WriteLine("STACK TRACE: " + ex.StackTrace);
                Console.WriteLine("GREŠKA: " + ex.Message);
                throw new UserException("An unexpected error occurred while creating the bid.");
            }
        }

        public override async Task<BidDTO> Update(int id, BidUpdateRequest request)
        {
            var bid = await _context.Bids.Include(b => b.Tender).FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new UserException("Bid not found");

            _logger.LogInformation("Attempting to update bid {BidId}", id);

            var state = CreateState(bid.Status, bid.Tender.Status);

            return await state.Update(id, request);
        }



        public async Task<BidDTO> Withdraw(int id)
        {
            var bid = await _context.Bids.Include(b => b.Tender).FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new UserException("Bid not found");

            _logger.LogInformation("Attempting to withdraw bid {BidId}", id);

            var state = CreateState(bid.Status, bid.Tender.Status);

            return await state.Withdraw(id);
        }

        public async Task<List<BidDTO>> GetBidsForTender(int tenderId)
        {
            var bids = await _context.Bids
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
                ApplicationStatus.Pending => _serviceProvider.GetRequiredService<OpenBidState>(),
                ApplicationStatus.Withdrawn => _serviceProvider.GetRequiredService<FinalBidState>(),
                ApplicationStatus.Accepted => _serviceProvider.GetRequiredService<FinalBidState>(),
                ApplicationStatus.Rejected => _serviceProvider.GetRequiredService<FinalBidState>(),
                _ => _serviceProvider.GetRequiredService<OpenBidState>()
            };
        }

    }
}
