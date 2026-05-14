using AutoMapper;
using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic; 
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Contracts;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.StateMachines.BidStates
{
    public class PendingBidState : BaseBidState
    {
        private readonly IPubSub _pubSub;
        public PendingBidState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper, IPubSub pubSub)
            : base(serviceProvider, context, mapper) { _pubSub = pubSub; }


        public override async Task<BidDTO> Insert(BidInsertRequest request)
        {
            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            var currentUserId = authService.GetCurrentUserId();

            var alreadyResponded = await _context.Bids
                .AnyAsync(b => b.TenderId == request.TenderId && b.SubmittedByUserId == currentUserId && b.Status != ApplicationStatus.Withdrawn);

            if (alreadyResponded)
            {
                throw new UserException("You already sent a bid.You can edit existing one or withdraw and create new one");
            }

            var tender = await _context.Tenders.FindAsync(request.TenderId);
            if (tender.Status != TenderStatus.Open)
            {
                throw new UserException("Tender isnt open to any more requests");
            }

            var entity = _mapper.Map<Bid>(request);
            entity.Status = ApplicationStatus.Pending;
            entity.SubmittedAt = DateTime.UtcNow;
            entity.SubmittedByUserId = currentUserId;

            _context.Bids.Add(entity);
            await _context.SaveChangesAsync();

            //rabbitmq zakomentarisan zasad

            //await _pubSub.PublishAsync(new BidCreatedEvent
            //{
            //    TenderId = entity.TenderId,
            //    OwnerUserId = tender.CreatedByUserId,
            //    OfferedPrice = entity.OfferedPrice
            //}, cfg => cfg.WithTopic("bid_created"));


            return _mapper.Map<BidDTO>(entity);
        }

        //public override async Task<BidDTO> Update(int id, BidUpdateRequest request)
        //{
        //    var bid = await _context.Bids.Include(b => b.Tender).FirstOrDefaultAsync(x => x.Id == id)
        //        ?? throw new NotFoundException("Bid not found",new { Bid="Bid",Id=id});

        //    var authService = _serviceProvider.GetRequiredService<IAuthService>();
        //    if (bid.SubmittedByUserId != authService.GetCurrentUserId())
        //    {
        //        throw new UserException("You can only modify your own bids.");
        //    }



        //    if (bid.Tender.Status != TenderStatus.Open)
        //        throw new UserException("Tender is no longer open for changes.");

        //    _mapper.Map(request, bid);
        //    await _context.SaveChangesAsync();
          

        //    return _mapper.Map<BidDTO>(bid);
        //}

        public override async Task<BidDTO> Cancel(int id)
        {
            var bid = await _context.Bids
                .Include(b => b.Tender)
                .FirstOrDefaultAsync(b=>b.Id==id)
                 ?? throw new NotFoundException("Bid not found", new { Bid = "Bid", Id = id });


            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            if (bid.SubmittedByUserId != authService.GetCurrentUserId())
            {
                throw new UserException("You can only withdraw your own bids.");
            }

            if (bid.Tender.Status != TenderStatus.Open)
                throw new UserException("Tender is no longer open for changes.");


            bid.Status = ApplicationStatus.Withdrawn;
            return _mapper.Map<BidDTO>(bid);
        }


        public override async Task<List<string>>AllowedActions(Bid entity)
        {

            var list =await base.AllowedActions(entity);
            var authService = _serviceProvider.GetRequiredService<IAuthService>();
            var currentUserId = authService.GetCurrentUserId();

            bool isBidOwner = entity.SubmittedByUserId == currentUserId;

            if (isBidOwner) {

                list.Add("Withdraw");
                list.Add("Update");
            }
            return list;

         
        }
    }
}
