using AutoMapper;
using AutoMapper.QueryableExtensions;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class TenderAdminService : ITenderAdminService
    {
        protected readonly TenderGoContext _context;
        protected readonly IMapper _mapper;

        public TenderAdminService(TenderGoContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<List<AdminTenderDTO>> GetAllTendersAsync()
        {
            return await _context.Tenders
                .OrderByDescending(t => t.CreatedAt)
                .ProjectTo<AdminTenderDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();
        }

        public async Task<PagedResult<TenderDTO>> AdminSearchAsync(AdminTenderSearchRequest request)
        {
            var page = Math.Max(request.Page, 1);
            var pageSize = Math.Max(request.PageSize, 1);

            var query = _context.Tenders.AsQueryable();

            if (request.Status.HasValue)
                query = query.Where(t => t.Status == request.Status.Value);

            if (request.CategoryId.HasValue)
                query = query.Where(t => t.CategoryId == request.CategoryId.Value);

            if (request.LocationId.HasValue)
                query = query.Where(t => t.LocationId == request.LocationId.Value);

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = request.SearchTerm.Trim().ToLower();
                var likeTerm = $"%{term}%";

                query = query.Where(t =>
                    EF.Functions.Like(t.Title.ToLower(), likeTerm) ||
                    (t.Description != null && EF.Functions.Like(t.Description.ToLower(), likeTerm)) ||
                    EF.Functions.Like(t.Category.Name.ToLower(), likeTerm) ||
                    EF.Functions.Like(t.Location.Name.ToLower(), likeTerm));
            }

            var totalCount = await query.CountAsync();

            var results = await query
                .OrderByDescending(t => t.PostedAt ?? t.Deadline)
                .ThenBy(t => t.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            return new PagedResult<TenderDTO>
            {
                Result = results,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }
    }
}
