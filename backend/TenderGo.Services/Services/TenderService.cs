using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class TenderService : BaseService<TenderDTO, Tender,TenderInsertRequest,TenderUpdateRequest>, ITenderService
    {
        public TenderService(TenderGoContext context, IMapper mapper,IHttpContextAccessor httpContextAccessor) : base(context, mapper,httpContextAccessor)
        {

        }






        public async Task<IEnumerable<TenderDTO>> GetClosedTenders()
        {
            var tenders = await _context.Tenders.Where(t => t.Status == TenderStatus.Closed).ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }

        public async Task<IEnumerable<TenderDTO>> GetActiveTenders()
        {
            var tenders = await _context.Tenders.Where(t => t.Status == TenderStatus.Open).ToListAsync();

            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }
        public async Task<IEnumerable<TenderDTO>> GetTendersByCategory(int id)
        {
            var tenders = await _context.Tenders
                .Where(t => t.CategoryId == id)
                .ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);


        }

     public async Task CloseTender(int tenderId)
        {
            var tender = await _context.Tenders.FindAsync(tenderId)
                ?? throw new UserException("Tender not found");
            tender.Status = TenderStatus.Closed;
            await _context.SaveChangesAsync();
        }

        public async Task AcceptBid(int tenderId, int bidId)
        {
            var tender = await _context.Tenders.FindAsync(tenderId)
                ?? throw new UserException("Tender not found");
            var bid = await _context.Bids.FindAsync(bidId)
                ?? throw new UserException("Bid not found");
            if (tender.Status != TenderStatus.Open)
                throw new UserException("Tender is not open");

            var application = tender.Applicants.FirstOrDefault(a => a.Id == bidId);
            if (application == null)
            {
                throw new UserException("Bidder did not apply for this tender");
            }



            foreach (var app in tender.Applicants)
            {
                app.Status =app.Id==bidId ? ApplicationStatus.Accepted : ApplicationStatus.Rejected;
            }

            tender.Status = TenderStatus.Closed;
            await _context.SaveChangesAsync();




        }
        }
}
