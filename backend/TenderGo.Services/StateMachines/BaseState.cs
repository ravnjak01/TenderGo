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
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.StateMachines
{
    public class BaseState
    {

        protected readonly TenderGoContext _context;
        protected readonly IMapper _mapper;
        protected readonly IServiceProvider _serviceProvider;
        protected readonly ILogger<BaseState> _logger;

        public BaseState(IServiceProvider serviceProvider, TenderGoContext context, IMapper mapper,ILogger<BaseState>logger)
        {
            _serviceProvider = serviceProvider;
            _context = context;
            _mapper = mapper;
            _logger = logger;
        }

        public virtual Task<TenderDTO> Insert(TenderInsertRequest request) => throw new UserException("Not allowed in this state");

        public virtual Task<TenderDTO> Update(int id, TenderUpdateRequest request) => throw new UserException("Not allowed in this state");

        public virtual Task<TenderDTO> Activate(int id) => throw new UserException("Not allowed in this state");

        public virtual Task<TenderDTO> Hide(int id) => throw new UserException("Not allowed in this state");

        public virtual Task<TenderDTO> Delete(int id) => throw new UserException("Not allowed in this state");

        public virtual Task<TenderDTO> Cancel(int id) => throw new UserException("Not allowed in this state");

        public virtual Task<TenderDTO> Close(int id) => throw new UserException("Not allowed in this state");

        public virtual Task<TenderDTO> Award(int id, int bidId) => throw new UserException("Not allowed in this state");

        public virtual Task<TenderDTO> Archive(int id) => throw new UserException("Not allowed in this state");
    }
}
