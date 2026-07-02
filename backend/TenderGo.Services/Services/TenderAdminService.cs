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

        public async Task<PagedResult<AdminTenderDTO>> GetAllTendersAsync(AdminTenderSearchRequest request)
        {
            var page = Math.Max(request.Page, 1);
            var pageSize = Math.Max(request.PageSize, 1);

            var query = _context.Tenders.AsQueryable();

            var totalCount = await query.CountAsync();

            var results = await query
                .OrderBy(t => t.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ProjectTo<AdminTenderDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            return new PagedResult<AdminTenderDTO>
            {
                Result = results,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }


        public async Task<PagedResult<AdminTenderDTO>> AdminSearchAsync(AdminTenderSearchRequest request)
        {
            var page = Math.Max(request.Page, 1);
            var pageSize = Math.Max(request.PageSize, 1);

            var query = _context.Tenders.AsQueryable();

            if (request.Status.HasValue)
            {
                query = query.Where(t => t.Status == request.Status.Value);
            }

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = request.SearchTerm.Trim().ToLower();
                var likeTerm = $"%{term}%";

                query = query.Where(t =>
                    EF.Functions.Like(t.Title.ToLower(), likeTerm) ||
                    (t.Description != null && EF.Functions.Like(t.Description.ToLower(), likeTerm)) ||
                    (t.Category != null && EF.Functions.Like(t.Category.Name.ToLower(), likeTerm)) ||
                    (t.Location != null && EF.Functions.Like(t.Location.Name.ToLower(), likeTerm)));
            }

            var totalCount = await query.CountAsync();

            var results = await query
                .OrderBy(t => t.CreatedAt) 
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ProjectTo<AdminTenderDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            return new PagedResult<AdminTenderDTO>
            {
                Result = results,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }
    }
}
