using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class CategoryService:BaseService<CategoryDTO,Category,CategoryDTO,CategoryUpdateRequest>,ICategoryService
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

      protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query)
{
    if (!_authService.IsInRole(AppRoles.Admin))
        return query.Where(c => c.IsActive);

    var includeInactiveQuery =
        _httpContextAccessor.HttpContext?.Request.Query["includeInactive"];

    var includeInactive =
        bool.TryParse(includeInactiveQuery, out var parsed)
        && parsed;

    if (includeInactive)
        return query;

    return query.Where(c => c.IsActive);
}

        public override async Task<string> Delete(int id)
        {
            var category = await _context.Categories.FindAsync(id)
                ?? throw new UserException("Category not found");

            var isUsedByTender = await _context.Tenders.AnyAsync(t => t.CategoryId == id);
            if (!isUsedByTender)
            {
                _context.Categories.Remove(category);
                await _context.SaveChangesAsync();
                return "Category deleted successfully.";
            }

            category.IsActive = false;
            await _context.SaveChangesAsync();
            return "Category is used by existing tenders and has been deactivated.";
        }

        public async Task<CategoryDTO> Activate(int id)
        {
            var category = await _context.Categories.FindAsync(id)
                ?? throw new UserException("Category not found");

            category.IsActive = true;
            await _context.SaveChangesAsync();

            return _mapper.Map<CategoryDTO>(category);
        }

    }
}
