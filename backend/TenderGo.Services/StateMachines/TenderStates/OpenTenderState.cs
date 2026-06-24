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

        public OpenTenderState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper, ILogger<OpenTenderState> logger)
            : base(serviceProvider, context, mapper, logger)
        {
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

        public override async Task<List<string>> AllowedActions(Tender entity)
        {
            var list = await base.AllowedActions(entity);

            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            var currentUserId = authService.GetCurrentUserId();

            bool isOwner = entity.CreatedByUserId == currentUserId;
            bool isAdmin = authService.IsInRole(AppRoles.Admin);

            if (!isOwner)
            {
                list.Add("SubmitBid");
            }

            if (isOwner || isAdmin)
            {
                list.Add("Cancel");
            }

            return list;
        }
    }
}
