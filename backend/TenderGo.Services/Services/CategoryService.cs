using AutoMapper;
using AutoMapper.QueryableExtensions;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class CategoryService : BaseService<CategoryDTO, Category, CategorySearchRequest,CategoryInsertRequest, CategoryUpdateRequest>, ICategoryService
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

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchRequest request)
        {
            // 1. Filtriranje po nazivu (SearchTerm iz PagedSearchRequest-a)
            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = $"%{request.SearchTerm.ToLower()}%";
                query = query.Where(c => EF.Functions.Like(c.Name.ToLower(), term));
            }

            // 2. Logika za aktivne/neaktivne kategorije
            var isAdmin = _authService.IsInRole(AppRoles.Admin);
            if (!isAdmin)
            {
                query = query.Where(c => c.IsActive);
            }
            else
            {
                var includeInactiveQuery = _httpContextAccessor.HttpContext?.Request.Query["includeInactive"];
                var includeInactive = bool.TryParse(includeInactiveQuery, out var parsed) && parsed;

                if (!includeInactive)
                {
                    query = query.Where(c => c.IsActive);
                }
            }

            // 3. Obavezno sortiranje za stabilnu paginaciju
            return query.OrderBy(c => c.Name);
        }

     
        public override async Task<CategoryDTO> Update(int id, CategoryUpdateRequest request)
        {
            var entity = await _context.Categories.FindAsync(id)
                ?? throw new UserException("Category not found.");

            if (request.Name == null && request.Description == null)
            {
                throw new UserException("No fields provided for update.");
            }

            if (request.Name != null)
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                    throw new UserException("Category name cannot be empty.");

                entity.Name = request.Name.Trim();
            }

            if (request.Description != null)
            {
                if (string.IsNullOrWhiteSpace(request.Description))
                    throw new UserException("Category description cannot be empty.");

                entity.Description = request.Description.Trim();
            }

            await _context.SaveChangesAsync();

            return _mapper.Map<CategoryDTO>(entity);
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

        public async Task<CategoryDTO> Deactivate(int id)
        {
            var category = await _context.Categories.FindAsync(id)
                ?? throw new UserException("Category not found");

            category.IsActive = false;
            await _context.SaveChangesAsync();

            return _mapper.Map<CategoryDTO>(category);
        }


        public async Task<List<CategoryStatsDTO>> GetCategoryStatisticsAsync()
        {
            return await _context.Categories
                .Select(c => new CategoryStatsDTO
                {
                    CategoryId = c.Id,
                    CategoryName = c.Name,
                    TenderCount = _context.Tenders.Count(t => t.CategoryId == c.Id),
                    Description= c.Description,
                    IsActive=c.IsActive
                })
                .OrderByDescending(c => c.TenderCount)
                .ToListAsync();
        }
    }
}
