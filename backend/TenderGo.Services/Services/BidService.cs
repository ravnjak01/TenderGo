using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
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

namespace TenderGo.Services.Services
{
   public class BidService : BaseService<BidDTO, Bid, BidInsertRequest, BidUpdateRequest>, IBidService
    {

        private readonly IAuthService _authService;
        public BidService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor,IAuthService authService) : base(context, mapper, httpContextAccessor)
        {
            _authService = authService;
        }



        public async Task AcceptBid(int tenderId, int bidId)
        {

            var currentUserId = _authService.GetCurrentUserId();

            var tender = await _context.Tenders
             .Include(t => t.Bids)
             .FirstOrDefaultAsync(t => t.Id == tenderId)
             ?? throw new UserException("Tender not found");


            if (tender.CreatedByUserId != currentUserId)
                throw new UserException("You are not the owner of this tender");

            if (tender.Status != TenderStatus.Open)
                throw new UserException("Tender is not open");


            var acceptedBid = tender.Bids.FirstOrDefault(b => b.Id == bidId)
           ?? throw new UserException("Bid not found for this tender");




            foreach (var bid in tender.Bids)
            {
                bid.Status = bid.Id == bidId
                    ? ApplicationStatus.Accepted
                    : ApplicationStatus.Rejected;
            }

            tender.Status = TenderStatus.Closed;
            await _context.SaveChangesAsync();

        }


        public async Task RejectBidAsync(int bidId)
        {
             var currentUserId = _authService.GetCurrentUserId();

    var bid = await _context.Bids
        .Include(b => b.Tender)
        .FirstOrDefaultAsync(b => b.Id == bidId)
        ?? throw new UserException("Bid not found");

    if (bid.Tender.CreatedByUserId != currentUserId)
        throw new UserException("You are not the owner of this tender");

    if (bid.Status != ApplicationStatus.Pending)
        throw new UserException("Only pending bids can be rejected");

    bid.Status = ApplicationStatus.Rejected;
    await _context.SaveChangesAsync();
        }




        public override async Task<BidDTO> Insert(BidInsertRequest request)
        {
            var currentUserId = _authService.GetCurrentUserId();

            var tender = await _context.Tenders.FindAsync(request.TenderId)
                ?? throw new UserException("Tender not found");

            if (tender.Status != TenderStatus.Open)
                throw new UserException("Cannot submit bid to a closed tender");

            if (tender.CreatedByUserId == currentUserId)
                throw new UserException("You cannot bid on your own tender");

            if (tender.Deadline < DateTime.UtcNow)
                throw new UserException("Tender deadline has passed");

            var existingBid = await _context.Bids
                .AnyAsync(b => b.TenderId == request.TenderId && b.SubmittedByUserId == currentUserId);
            if (existingBid)
                throw new UserException("You have already submitted a bid for this tender");

            var entity = _mapper.Map<Bid>(request);
            entity.SubmittedByUserId = currentUserId;
            entity.Status = ApplicationStatus.Pending;
            entity.SubmittedAt = DateTime.UtcNow;

            _context.Bids.Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<BidDTO>(entity);
        }
    }
}
