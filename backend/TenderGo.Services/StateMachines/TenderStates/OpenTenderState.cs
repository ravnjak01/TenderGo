using AutoMapper;
using EasyNetQ;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using TenderGo.Api.Database;
using TenderGo.Contracts;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.StateMachines.TenderStates
{
    public class OpenTenderState : BaseState
    {
        private readonly IPubSub _pubSub;

        public OpenTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper, ILogger<OpenTenderState> logger, IPubSub pubSub)
            : base(serviceProvider, context, mapper, logger)
        {
            _pubSub = pubSub;
        }

        public override async Task<TenderDTO> Cancel(int id)
        {
            var tender = await _context.Tenders.FindAsync(id)
                            ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            bool isAdmin = authService.IsInRole(AppRoles.Admin);
            if (tender.CreatedByUserId != authService.GetCurrentUserId() && !isAdmin)
                throw new UserException("You can only cancel your own tenders");

            tender.Status = TenderStatus.Cancelled;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Tender with ID {TenderId} has been cancelled while in Open state", id);

            return _mapper.Map<TenderDTO>(tender);
        }

        public override async Task<TenderDTO> Close(int id)
        {
            var entity = await _context.Tenders.FindAsync(id)
                ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            if (entity.CreatedByUserId != authService.GetCurrentUserId())
            {
                throw new UserException("Only the owner can close the tender.");
            }

            if (entity.Deadline > DateTime.UtcNow)
            {
                throw new UserException("The tender cannot be closed before the application deadline expires.");
            }

            entity.Status = TenderStatus.Closed;
            await _context.SaveChangesAsync();

            try
            {
                await _pubSub.PublishAsync(
                    new TenderExpiredEvent
                    {
                        TenderId = entity.Id,
                        TenderTitle = entity.Title,
                        OwnerUserId = entity.CreatedByUserId,
                        ExpiredAt = DateTime.UtcNow
                    },
                    cfg => cfg.WithTopic("tender_expired"));
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Tender {TenderId} was closed but TenderExpiredEvent was not published",
                    entity.Id);
            }

            _logger.LogInformation("Tender {Id} was successfully closed by user {UserId}", id, entity.CreatedByUserId);

            return _mapper.Map<TenderDTO>(entity);
        }

        public override async Task<List<string>> AllowedActions(Tender entity)
        {
            var list = await base.AllowedActions(entity);

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            var currentUserId = authService.GetCurrentUserId();
            bool isOwner = entity.CreatedByUserId == currentUserId;
            bool isAdmin = authService.IsInRole(AppRoles.Admin);
            if (entity.Deadline > DateTime.UtcNow)
            {
                if (!isOwner)
                {
                    list.Add("SubmitBid");
                }
            }
            else
            {
                if (isOwner)
                {
                    list.Add("Close");
                }
            }
            if (isOwner || isAdmin)
            {
                list.Add("Cancel");
            }

            return list;
        }
    }
}
