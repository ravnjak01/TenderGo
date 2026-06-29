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
    public class CategoryService : BaseService<CategoryDTO, Category, CategoryInsertRequest, CategoryUpdateRequest>, ICategoryService
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

        public async Task<PagedResult<CategoryDTO>> SearchAsync(CategorySearchRequest request)
        {
            var page = Math.Max(request.Page, 1);
            var pageSize = Math.Max(request.PageSize, 1);
            var query = _context.Categories.AsQueryable();

            if (request.IsActive.HasValue)
            {
                query = query.Where(c => c.IsActive == request.IsActive.Value);
            }
            else
            {
                query = ApplyFilter(query);
            }

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = request.SearchTerm.Trim().ToLower();
                var likeTerm = $"%{term}%";

                query = query.Where(c => EF.Functions.Like(c.Name.ToLower(), likeTerm));
            }

            var totalCount = await query.CountAsync();

            var results = await query
                .OrderBy(c => c.Name)
                .ThenBy(c => c.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ProjectTo<CategoryDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            return new PagedResult<CategoryDTO>
            {
                Result = results,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
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
