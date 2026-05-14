using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.StateMachines.BidStates
{
    public class BaseBidState
    {
        protected readonly TenderGoContext _context;
        protected readonly IMapper _mapper;
        protected readonly IServiceProvider _serviceProvider;

        public BaseBidState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper)
        {
            _serviceProvider = serviceProvider;
            _context = context;
            _mapper = mapper;
        }

        
        public virtual Task<BidDTO> Insert(BidInsertRequest request) => throw new ForbiddenException("Not allowed");
       // public virtual Task<BidDTO> Update(int id, BidUpdateRequest request) => throw new ForbiddenException("Not allowed");
        public virtual Task<BidDTO> Withdraw(int id) => throw new ForbiddenException("Not allowed");
        public virtual Task<BidDTO> Cancel(int id) => throw new UserException("Not allowed in this state");

        public virtual Task<List<string>> AllowedActions(Bid entity)
        {
            return Task.FromResult(new List<string>()); 
        }
    }
}
