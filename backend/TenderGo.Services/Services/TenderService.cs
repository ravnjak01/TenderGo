using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
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
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class TenderService : BaseService<TenderDTO, Tender,TenderInsertRequest,TenderUpdateRequest>, ITenderService
    {

        private readonly IAuthService _authService;
        protected readonly ILogger<TenderService> _logger;
        public TenderService(TenderGoContext context, IMapper mapper,IHttpContextAccessor httpContextAccessor,IAuthService authService,ILogger<TenderService>logger) : base(context, mapper,httpContextAccessor)
        {
            _logger = logger;
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


        public async Task<List<TenderDTO>> GetTendersByUser(string userId)
        {
            var tenders = await _context.Tenders
                      .Where(t => t.CreatedByUserId == userId)
                       .OrderByDescending(t => t.CreatedAt)
                       .ToListAsync();
            return _mapper.Map<List<TenderDTO>>(tenders);
        }

        public async Task CancelTender(int tenderId)
        {

            _logger.LogInformation("Attempting to cancel tender with ID {TenderId}", tenderId);
            var currentUserId = _authService.GetCurrentUserId();

            var tender = await _context.Tenders.FindAsync(tenderId)
                ?? throw new NotFoundException(nameof(Tender), tenderId);

            if (tender.CreatedByUserId != currentUserId)
                throw new ForbiddenException("You are not the owner of this tender");

            if (tender.Status != TenderStatus.Open)
                throw new UserException("Only open tenders can be cancelled");

            await _context.Bids
                .Where(b => b.TenderId == tenderId)
                .ExecuteUpdateAsync(b => b.SetProperty(x => x.Status, ApplicationStatus.Rejected));

            tender.Status = TenderStatus.Cancelled;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Tender with ID {TenderId} has been cancelled", tenderId);
        }

     

        public override async Task<TenderDTO>Insert( TenderInsertRequest request)
        {
            _logger.LogInformation("Attempting to create a new tender with title {Title}", request.Title);

            if (request.Deadline <= DateTime.UtcNow)
                throw new UserException("Deadline must be in the future");

            var entity = _mapper.Map<Tender>(request);

            entity.CreatedByUserId = _authService.GetCurrentUserId();
            entity.Status = TenderStatus.Open;

            _context.Set<Tender>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<TenderDTO>(entity);

            _logger.LogInformation("Tender with title {Title} has been created with ID {TenderId}", request.Title, entity.Id);
        }


        public override async Task Update(int id, TenderUpdateRequest request)
        {

            _logger.LogInformation("Attempting to update tender with ID {TenderId}", id);

            var tender = await _context.Tenders.FindAsync(id)
                ?? throw new UserException("Tender not found");

            if (tender.CreatedByUserId != _authService.GetCurrentUserId())
                throw new UserException("You can only edit your own tenders");

            if (tender.Status != TenderStatus.Open)
                throw new UserException("Cannot edit a tender that is not open");

            _mapper.Map(request, tender);
            await _context.SaveChangesAsync();


            _logger.LogInformation("Tender with ID {TenderId} has been updated", id);
        }


    }
}
