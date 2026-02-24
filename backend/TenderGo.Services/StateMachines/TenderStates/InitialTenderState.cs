using AutoMapper;
using EasyNetQ;
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


            if (request.Deadline <= DateTime.UtcNow)
                throw new UserException("Deadline must be in the future");

            var entity = _mapper.Map<Tender>(request);

            entity.Status = TenderStatus.Draft;
            entity.CreatedAt = DateTime.UtcNow;


            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            entity.CreatedByUserId = authService.GetCurrentUserId();


            _context.Tenders.Add(entity);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Tender {Id} created as Draft.", entity.Id);
            return _mapper.Map<TenderDTO>(entity);

        }

        public override async Task<TenderDTO> Update(int id, TenderUpdateRequest request)
        {
            var entity = await _context.Tenders.FindAsync(id)
                ?? throw new UserException("Tender not found");

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
                ?? throw new UserException("Tender not found");

            var authService = _serviceProvider.GetRequiredService<IAuthService>();

            if (entity.CreatedByUserId != authService.GetCurrentUserId())
                throw new UserException("You can only activate your own tenders");

            _logger.LogInformation("Attempting to activate tender with ID {TenderId}", id);

            entity.Status = TenderStatus.Open;

            await _context.SaveChangesAsync();

            var mappedEntity=_mapper.Map<TenderDTO>(entity);
            await _pubSub.PublishAsync(mappedEntity, "tender_updates");

            try
            {
                var factory=new ConnectionFactory() { HostName = "localhost" };
                using var connection = await factory.CreateConnectionAsync();
                using var channel = await connection.CreateChannelAsync();

                await channel.QueueDeclareAsync(queue: "tender_updates",
                                     durable: false,
                                     exclusive: false,
                                     autoDelete: false,
                                     arguments: null);

                const string message= "Hello world";
                var body = Encoding.UTF8.GetBytes(message);

               await channel.BasicPublishAsync(exchange: string.Empty,
                                     routingKey: "tender_updates",
                                     body: body);


            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish message to RabbitMQ for tender activation.");
            }
            return _mapper.Map<TenderDTO>(entity);

        }
    }
}
