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
   public class BidService : BaseService<BidDTO, Bid,PagedSearchRequest, BidInsertRequest, BidDTO>, IBidService
    {

        private readonly IAuthService _authService;
        protected readonly ILogger<BidService> _logger;
        protected readonly IServiceProvider _serviceProvider;
        public BidService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor,
            IAuthService authService, ILogger<BidService> logger, IServiceProvider serviceProvider) : base(context, mapper, httpContextAccessor)
        {
            _authService = authService;
            _logger = logger;
            _serviceProvider = serviceProvider;
        }


        protected override IQueryable<Bid> ApplySorting(IQueryable<Bid> query)
        {
            return query.OrderByDescending(b => b.SubmittedAt);
        }
        public override async Task<BidDTO> GetById(int id)
        {
            var query = _context.Bids
                .Include(b => b.Tender)
                .AsQueryable();

            query = AddIncludes(query);

            var entity = await query.FirstOrDefaultAsync(b => b.Id == id)
                 ?? throw new NotFoundException("Bid not found", new { Entity = "Bid", Id = id });

            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

       
            bool isBidAuthor = entity.CreatedByUserId == currentUserId;
            bool isTenderOwner = entity.Tender != null && entity.Tender.CreatedByUserId == currentUserId;

            if (!isAdmin && !isBidAuthor && !isTenderOwner)
            {
                throw new ForbiddenException();
            }

            return _mapper.Map<BidDTO>(entity);


        }

        public async Task<PagedResult<BidDTO>> GetBidsByUser(string userId, PagedSearchRequest request)
        {
            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (userId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();
            }

            var query = _context.Bids
                .AsNoTracking()
                .Where(x => x.SubmittedByUserId == userId && x.Status != ApplicationStatus.Withdrawn);

            var totalCount = await query.CountAsync();

            int page = request.Page > 0 ? request.Page : 1;
            int pageSize = request.PageSize > 0 ? Math.Min(request.PageSize, 50) : 10;
            int maxPageSize = 100;

            if(pageSize > maxPageSize)
            {
                pageSize = maxPageSize;
            }
            var bids = await query
                .OrderByDescending(x => x.CreatedAt) 
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ProjectTo<BidDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            if (bids.Any())
            {
                var tenderIds = bids.Select(b => b.TenderId).Distinct().ToList();

                var ratedPairs = await _context.Ratings
                    .AsNoTracking()
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
            }

            return new PagedResult<BidDTO>
            {
                Result = bids,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
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

   
        var totalAttempts = await _context.Bids
            .CountAsync(b => b.TenderId == request.TenderId 
                          && b.SubmittedByUserId == currentUserId);

        if (totalAttempts >= 3)
        {
            throw new UserException("MAX_BID_ATTEMPTS_EXCEEDED");
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

        public async Task<PagedResult<BidDTO>> GetBidsForTender(int tenderId, PagedSearchRequest request)
        {
            var tender = await _context.Tenders.FindAsync(tenderId)
                      ?? throw new NotFoundException("Tender", tenderId);

            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (tender.CreatedByUserId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();
            }

            var query = _context.Bids
                .AsNoTracking()
                .Where(b => b.TenderId == tenderId);

            const int maxPageSize = 100;
            int page = request.Page > 0 ? request.Page : 1;
            int pageSize = request.PageSize > 0 ? request.PageSize : 10;

            if (pageSize > maxPageSize)
            {
                pageSize = maxPageSize;
            }

            var totalCount = await query.CountAsync();

            var bids = await query
                .OrderByDescending(b => b.SubmittedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ProjectTo<BidDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            var currentPageUserIds = bids.Select(b => b.SubmittedByUserId).Distinct().ToList();

            var ratedUserIds = await _context.Ratings
                .Where(r => r.RatedByUserId == currentUserId
                         && r.TenderId == tenderId
                         && currentPageUserIds.Contains(r.RatedUserId))
                .Select(r => r.RatedUserId)
                .ToListAsync();

            foreach (var bid in bids)
            {
                bid.AlreadyRated = ratedUserIds.Contains(bid.SubmittedByUserId);
            }

            return new PagedResult<BidDTO>
            {
                Result = bids,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
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
