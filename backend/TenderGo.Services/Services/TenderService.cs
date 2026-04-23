using AutoMapper;
using EasyNetQ;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
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
using TenderGo.Services.StateMachines.TenderStates;

namespace TenderGo.Services.Services
{
    public class TenderService : BaseService<TenderDTO, Tender, TenderInsertRequest, TenderUpdateRequest>, ITenderService
    {

        private readonly IAuthService _authService;
        protected readonly ILogger<TenderService> _logger;
        protected readonly IServiceProvider _serviceProvider;
        public TenderService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor, IAuthService authService, ILogger<TenderService> logger, IServiceProvider serviceProvider) : base(context, mapper, httpContextAccessor)
        {
            _logger = logger;
            _authService = authService;
            _serviceProvider = serviceProvider;
        }

        protected override IQueryable<Tender> AddIncludes(IQueryable<Tender> query)
        {
            return query
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Bids)
                .Include(t => t.Images);
        }

        public async Task<IEnumerable<TenderDTO>> GetActiveTenders()
        {
            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)  
                .Include(t => t.Images)
                .Where(t => t.Status == TenderStatus.Open)
                .ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }
        public async Task<IEnumerable<TenderDTO>> GetClosedTenders()
        {
            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Images)
                .Where(t => t.Status == TenderStatus.Closed)
                .ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }

        public async Task<IEnumerable<TenderDTO>> GetDraftTenders()
        {
            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Images)
                .Where(t => t.Status == TenderStatus.Draft)
                .ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }

        public async Task<IEnumerable<TenderDTO>> GetCancelledTenders()
        {
            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Images)
                .Where(t => t.Status == TenderStatus.Cancelled)
                .ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }

        public async Task<IEnumerable<TenderDTO>> GetTendersByCategory(int id)
        {
            var categoryExists = await _context.Categories.AnyAsync(c => c.Id == id);
            if (!categoryExists)
                throw new NotFoundException("Category not found", new { CategoryId = id });

            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Images)
                .Where(t => t.CategoryId == id)
                .ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }

        public async Task<List<TenderDTO>> GetTendersByUser(string userId)
        {
            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Images)
                .Where(t => t.CreatedByUserId == userId)
                .OrderByDescending(t => t.CreatedAt)
                .ToListAsync();
            return _mapper.Map<List<TenderDTO>>(tenders);
        }


        public override async Task<TenderDTO> Insert(TenderInsertRequest request)
        {
            _logger.LogInformation("Posting tender {Title}", request.Title);

            if (request.Deadline <= DateTime.UtcNow)
                throw new UserException("Deadline must be in the future");

            try  // 
            {
                var entity = _mapper.Map<Tender>(request);
                _logger.LogInformation("ImageUrls in request: {Count}", request.ImageUrls?.Count ?? 0);
                _logger.LogInformation("Images mapped to entity: {Count}", entity.Images?.Count ?? 0);

                if (!string.IsNullOrWhiteSpace(request.LocationName))
                {
                    var parts = request.LocationName.Split(',');
                    entity.LocationName = parts.Length >= 2 ? parts[0].Trim() : request.LocationName.Trim();
                    entity.Country = parts.Length >= 2 ? parts[1].Trim() : "Unknown";
                }

                entity.Status = TenderStatus.Open;
                entity.PostedAt = DateTime.UtcNow;
                entity.CreatedAt = DateTime.UtcNow;
                entity.CreatedByUserId = _authService.GetCurrentUserId();

                var images = entity.Images.ToList();
                for (int i = 0; i < images.Count; i++)
                {
                    images[i].IsPrimary = (i == 0);
                    images[i].Tender = entity;
                }

                _context.Tenders.Add(entity);
                await _context.SaveChangesAsync();

                var saved = await _context.Tenders
                    .Include(t => t.CreatedByUser)
                    .Include(t => t.Category)
                    .Include(t => t.Images)
                    .Include(t => t.Bids)
                    .FirstAsync(t => t.Id == entity.Id);

                return _mapper.Map<TenderDTO>(saved);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error inserting tender: {Message}", ex.Message);
                throw; 
            }
        }




        public override async Task<TenderDTO> Update(int id, TenderUpdateRequest request)
        {

            _logger.LogInformation("Attempting to update tender with ID {TenderId}", id);



            var tender = await _context.Tenders.FindAsync(id)
                ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });

         
            var state = CreateState(tender.Status);
             return await state.Update(id, request);
        }

        public async Task<TenderDTO> Publish(int id)
        {
            var entity = await _context.Tenders.FindAsync(id)
                         ?? throw new NotFoundException("Tender not found",new {Entity="Tender",Id=id});

            var state = CreateState(entity.Status);
            return await state.Activate(id);
        }

        public async Task<TenderDTO> SaveDraft(TenderInsertRequest request)
        {
            _logger.LogInformation(
                "Attempting to save tender draft with title {Title}",
                request.Title
            );

            var state = CreateState(TenderStatus.Draft);
            return await state.Insert(request);
        }


        public async Task<TenderDTO> Cancel(int id)
        {
            var entity = await _context.Tenders.FindAsync(id)
                              ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });


            var state = CreateState(entity.Status);
            return await state.Cancel(id);
        }


        public async Task<TenderDTO> Award(int id, int bidId)
        {
            var tender = await _context.Tenders
        .Include(t => t.Bids)
        .FirstOrDefaultAsync(t => t.Id == id)
        ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });

            var state = CreateState(tender.Status);

            var resultDto = await state.Award(tender, bidId);

            await _context.SaveChangesAsync();

            return resultDto;
        }


        public async Task<List<string>> AllowedActions(int id)
        {
            var entity = await _context.Tenders
           .Include(t => t.Bids) 
           .FirstOrDefaultAsync(t => t.Id == id)
                         ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });



            var state = CreateState(entity.Status);

            return await state.AllowedActions(entity);
        }

        public BaseState CreateState(TenderStatus status)
        {
            return status switch
            {
                TenderStatus.Draft => _serviceProvider.GetRequiredService<InitialTenderState>(),
                TenderStatus.Open => _serviceProvider.GetRequiredService<OpenTenderState>(),
                TenderStatus.Closed => _serviceProvider.GetRequiredService<ClosedTenderState>(),
                TenderStatus.Awarded => _serviceProvider.GetRequiredService<AwardedTenderState>(),
                TenderStatus.Cancelled => _serviceProvider.GetRequiredService<CancelledTenderState>(),
                _ => throw new UserException("Invalid tender status")
            };
        }



    }
}
