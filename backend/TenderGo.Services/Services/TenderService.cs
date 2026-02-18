using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
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
    public class TenderService : BaseService<TenderDTO, Tender,TenderInsertRequest,TenderUpdateRequest>, ITenderService
    {

        private readonly IAuthService _authService;
        public TenderService(TenderGoContext context, IMapper mapper,IHttpContextAccessor httpContextAccessor,IAuthService authService) : base(context, mapper,httpContextAccessor)
        {
            _authService = authService;
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

        public async Task CancelTender(int tenderId)
        {
            var currentUserId = _authService.GetCurrentUserId();

            var tender = await _context.Tenders.FindAsync(tenderId)
                ?? throw new UserException("Tender not found");

            if (tender.CreatedByUserId != currentUserId)
                throw new UserException("You are not the owner of this tender");

            if (tender.Status != TenderStatus.Open)
                throw new UserException("Only open tenders can be cancelled");

            await _context.Bids
                .Where(b => b.TenderId == tenderId)
                .ExecuteUpdateAsync(b => b.SetProperty(x => x.Status, ApplicationStatus.Rejected));

            tender.Status = TenderStatus.Cancelled;
            await _context.SaveChangesAsync();
        }

     

        public override async Task<TenderDTO>Insert( TenderInsertRequest request)
        {

            if (request.Deadline <= DateTime.UtcNow)
                throw new UserException("Deadline must be in the future");

            var entity = _mapper.Map<Tender>(request);

            entity.CreatedByUserId = _authService.GetCurrentUserId();
            entity.Status = TenderStatus.Open;

            _context.Set<Tender>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<TenderDTO>(entity);
        }


        public override async Task Update(int id, TenderUpdateRequest request)
        {
            var tender = await _context.Tenders.FindAsync(id)
                ?? throw new UserException("Tender not found");

            if (tender.CreatedByUserId != _authService.GetCurrentUserId())
                throw new UserException("You can only edit your own tenders");

            if (tender.Status != TenderStatus.Open)
                throw new UserException("Cannot edit a tender that is not open");

            _mapper.Map(request, tender);
            await _context.SaveChangesAsync();
        }


    }
}
