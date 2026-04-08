using AutoMapper;
using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
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

namespace TenderGo.Services.StateMachines.TenderStates
{
    public class InitialTenderState : BaseState
    {

        private readonly IPubSub _pubSub;

        public InitialTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper, ILogger<InitialTenderState> logger, IPubSub pubSub) : base(serviceProvider, context, mapper, logger)
        {
            _pubSub = pubSub;
        }
        public override async Task<TenderDTO> Insert(TenderInsertRequest request)
        {

            _logger.LogInformation("DEBUG: Request Location: {Loc}", request.LocationName);

            if (request.Deadline <= DateTime.UtcNow)
                throw new UserException("Deadline must be in the future");

            var entity = _mapper.Map<Tender>(request);

            if (!string.IsNullOrWhiteSpace(request.LocationName))
            {
                var parts = request.LocationName.Split(',');

                if (parts.Length >= 2)
                {
                    entity.LocationName = parts[0].Trim(); 
                    entity.Country = parts[1].Trim();      
                }
                else
                {
                    entity.LocationName = request.LocationName.Trim();
                    entity.Country = "Unknown"; 
                }
            }


            _logger.LogInformation("DEBUG: Entity Location after mapping: {Loc}", entity.LocationName);

            entity.Status = TenderStatus.Draft;
            entity.CreatedAt = DateTime.UtcNow;
                

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            entity.CreatedByUserId = authService.GetCurrentUserId();


            _context.Tenders.Add(entity);
            await _context.SaveChangesAsync();

            var saved = await _context.Tenders
                   .Include(t => t.CreatedByUser)
                   .Include(t => t.Category)
                   .Include(t => t.Images)
                   .Include(t => t.Bids)
                   .FirstAsync(t => t.Id == entity.Id);

            _logger.LogInformation("Tender {Id} created as Draft.", entity.Id);
            return _mapper.Map<TenderDTO>(saved);

        }

        public override async Task<TenderDTO> Update(int id, TenderUpdateRequest request)
        {
            var entity = await _context.Tenders.FindAsync(id)
                    ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });


            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            if (entity.CreatedByUserId != authService.GetCurrentUserId())
                throw new UserException("You can only edit your own tenders");

            _mapper.Map(request, entity);


            await _context.SaveChangesAsync();

            _logger.LogInformation("Tender {Id} was edited while in Open state.", id);
            return _mapper.Map<TenderDTO>(entity);
        }




        public override async Task<TenderDTO> Activate(int id)
        {
            var entity = await _context.Tenders.FindAsync(id)
                     ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });


            var authService = _serviceProvider.GetRequiredService<IAuthService>();

            if (entity.CreatedByUserId != authService.GetCurrentUserId())
                throw new UserException("You can only activate your own tenders");

            _logger.LogInformation("Attempting to activate tender with ID {TenderId}", id);

            if (entity.Status == TenderStatus.Draft) 
            {
                entity.PostedAt = DateTime.UtcNow;
            }
            entity.Status = TenderStatus.Open;

            await _context.SaveChangesAsync();

            var mappedEntity=_mapper.Map<TenderDTO>(entity);

            try
            {
                await _pubSub.PublishAsync(mappedEntity, "tender_updates");


            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish message to RabbitMQ for tender activation.");
            }
            return mappedEntity;

        }
    }
}
