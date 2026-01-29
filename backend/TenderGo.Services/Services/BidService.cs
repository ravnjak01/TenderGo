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
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
   public class BidService : BaseService<BidDTO, Bid, BidInsertRequest, BidUpdateRequest>, IBidService
    {

        private readonly IAuthService _authService;
        public BidService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor,IAuthService authService) : base(context, mapper, httpContextAccessor)
        {
            authService = _authService;
        }

         public async Task AcceptBidAsync(int bidId)
        {
          
            var bid =await _context.Bids
                .Include(b => b.Tender)
                .ThenInclude(t=>t.Applicants)
                .FirstOrDefaultAsync(b => b.Id == bidId);
            if (bid == null)
            {
                throw new Exception("Bid not found");
            }

            if (bid.Tender.Status != Models.ENUMs.TenderStatus.Open)
            {
                throw new Exception("Cannot accept bid for a closed tender");
            }

            foreach (var b in bid.Tender.Applicants)
                b.Status = b.Id == bidId ? ApplicationStatus.Accepted : ApplicationStatus.Rejected;
            bid.Tender.Status = TenderStatus.Closed;


            await _context.SaveChangesAsync();


        }

   
       

      
        public async Task RejectBidAsync(int bidId)
        {
            var bid = await _context.Bids.FindAsync(bidId);

            if (bid == null)
                throw new UserException("Bid not found");

            if (bid.Status != ApplicationStatus.Pending)
                throw new UserException("Only pending bids can be rejected");

            bid.Status = ApplicationStatus.Rejected;
            await _context.SaveChangesAsync();
        }

      
        public async Task<BidDTO> SubmitBidAsync(BidInsertRequest request)
        {
           var tender=await _context.Tenders
                .FirstOrDefaultAsync(t => t.Id == request.TenderId);

            if (tender == null)
            {
                throw new UserException("Tender not found");
            }

            if (tender.Status != TenderStatus.Open)
            {
                throw new UserException("Cannot submit bid to a closed tender");
            }


            var bid = _mapper.Map<Bid>(request);
            bid.Status = ApplicationStatus.Pending;

            _context.Bids.Add(bid);
            await _context.SaveChangesAsync();
            BidDTO bidDto = _mapper.Map<BidDTO>(bid);
            return bidDto;
        }


        public override async Task<BidDTO> Insert(BidInsertRequest request)
        {
            var entity = _mapper.Map<Bid>(request);

            entity.SubmittedByUserId = _authService.GetCurrentUserId();

            _context.Set<Bid>().Add(entity);
            await _context.SaveChangesAsync();

            var result = await _context.Set<Bid>()
        .Include(x => x.SubmittedByUser)
        .FirstOrDefaultAsync(x => x.Id == entity.Id);

            return _mapper.Map<BidDTO>(entity);
        }
    }
}
