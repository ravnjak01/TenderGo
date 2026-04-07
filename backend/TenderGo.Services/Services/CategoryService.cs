using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class CategoryService:BaseService<CategoryDTO,Category,CategoryDTO,CategoryDTO>,ICategoryService
    {

        private readonly IAuthService _authService;
        protected readonly ILogger<CategoryService> _logger;
        protected readonly IServiceProvider _serviceProvider;
        public CategoryService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor, IAuthService authService, ILogger<CategoryService> logger, IServiceProvider serviceProvider) : base(context, mapper, httpContextAccessor)
        {
            _logger = logger;
            _authService = authService;
            _serviceProvider = serviceProvider;
        }

    }
}
