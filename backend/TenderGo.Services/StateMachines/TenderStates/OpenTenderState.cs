using AutoMapper;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.StateMachines.TenderStates
{
    public class OpenTenderState : BaseState
    {
        public OpenTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper,ILogger<OpenTenderState> logger)
            : base(serviceProvider, context, mapper,logger)
        { }

        public override async Task<TenderDTO> Update(int id, TenderUpdateRequest request)
        {
            var entity = await _context.Tenders.FindAsync(id)
                ?? throw new UserException("Tender not found");

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            if (entity.CreatedByUserId != authService.GetCurrentUserId())
                throw new UserException("You can only edit your own tenders");

            _mapper.Map(request, entity);

            entity.IsEdited = true;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Tender {Id} was edited while in Open state.", id);
            return _mapper.Map<TenderDTO>(entity);
        }

        public override async Task<TenderDTO> Cancel(int id)
        {
            var tender = await _context.Tenders.FindAsync(id)
                         ?? throw new UserException("Tender not found");

            var authService = _serviceProvider.GetRequiredService<IAuthService>();

            if (tender.CreatedByUserId != authService.GetCurrentUserId())
                throw new UserException("You can only cancel your own tenders");

            tender.Status = TenderStatus.Cancelled;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Tender with ID {TenderId} has been cancelled while in Open state", id);

            return _mapper.Map<TenderDTO>(tender);
        }

        public override async Task<TenderDTO> Close(int id)
        {
            var entity = await _context.Tenders.FindAsync(id);

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            if (entity.CreatedByUserId != authService.GetCurrentUserId())
                throw new UserException("Only owner can close tender");

            entity.Status = TenderStatus.Closed;    
            await _context.SaveChangesAsync();

            _logger.LogInformation("Tender {Id} has been manually closed by user {UserId}", id, entity.CreatedByUserId);

            return _mapper.Map<TenderDTO>(entity);
        }

    }
}
        
