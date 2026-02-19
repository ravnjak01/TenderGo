using AutoMapper;
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
using TenderGo.Services.StateMachines;
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






        public async Task<IEnumerable<TenderDTO>> GetClosedTenders()
        {
            var tenders = await _context.Tenders.Where(t => t.Status == TenderStatus.Closed).ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }

        public async Task<IEnumerable<TenderDTO>> GetActiveTenders()
        {
            var tenders = await _context.Tenders
                .Include(t => t.Images)
                .Where(t => t.Status == TenderStatus.Open).ToListAsync();

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


        public override async Task<TenderDTO> Insert(TenderInsertRequest request)
        {
            _logger.LogInformation("Attempting to create a new tender with title {Title}", request.Title);


            var state = CreateState(TenderStatus.Draft);

            return await state.Insert(request); 

          
        }


        public override async Task<TenderDTO> Update(int id, TenderUpdateRequest request)
        {

            _logger.LogInformation("Attempting to update tender with ID {TenderId}", id);



            var tender = await _context.Tenders.FindAsync(id)
                ?? throw new UserException("Tender not found");

         
            var state = CreateState(tender.Status);
             return await state.Update(id, request);
        }

        public async Task<TenderDTO> Activate(int id)
        {
            var entity = await _context.Tenders.FindAsync(id)
                         ?? throw new UserException("Tender not found");

            var state = CreateState(entity.Status);
            return await state.Activate(id);
        }

        public async Task<TenderDTO> Cancel(int id)
        {
            var entity = await _context.Tenders.FindAsync(id)
                         ?? throw new UserException("Tender not found");

            var state = CreateState(entity.Status);
            return await state.Cancel(id);
        }


        public async Task<TenderDTO> Award(int id, int bidId)
        {
            var tender = await _context.Tenders.FindAsync(id);
            var state = CreateState(tender.Status);
            return await state.Award(id, bidId);
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
                TenderStatus.Archived => _serviceProvider.GetRequiredService<ArchivedTenderState>(),
                _ => throw new UserException("Invalid tender status")
            };
        }



    }
}
