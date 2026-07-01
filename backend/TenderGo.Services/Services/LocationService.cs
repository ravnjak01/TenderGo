using AutoMapper;
using AutoMapper.QueryableExtensions;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using QuestPDF.Helpers;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class LocationService : BaseService<LocationDTO, Location, LocationInsertRequest, LocationUpdateRequest>, ILocationService
    {
        private readonly IAuthService _authService;
        protected readonly ILogger<CategoryService> _logger;
        protected readonly IServiceProvider _serviceProvider;

        public LocationService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor, IAuthService authService, ILogger<CategoryService> logger, IServiceProvider serviceProvider) : base(context, mapper, httpContextAccessor)
        {
            _logger = logger;
            _authService = authService;
            _serviceProvider = serviceProvider;
        }

        protected override IQueryable<Location> ApplyFilter(IQueryable<Location> query)
        {
            if (!_authService.IsInRole(AppRoles.Admin))
                return query.Where(l => l.IsActive);

            var includeInactiveQuery =
                _httpContextAccessor.HttpContext?.Request.Query["includeInactive"];

            var includeInactive =
                bool.TryParse(includeInactiveQuery, out var parsed)
                && parsed;

            if (includeInactive)
                return query;

            return query.Where(l => l.IsActive);
        }

        public async Task<PagedResult<LocationDTO>> GetAdminLocationsPagedAsync(LocationSearchRequest request)
        {
            var page = Math.Max(request.Page, 1);
            var pageSize = Math.Clamp(request.PageSize, 1, 100);

            var query = _context.Locations.AsQueryable();

            if (request.IsActive.HasValue)
            {
                query = query.Where(l => l.IsActive == request.IsActive.Value);
            }

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = request.SearchTerm.Trim().ToLower();
                var likeTerm = $"%{term}%";

                query = query.Where(l =>
                    EF.Functions.Like(l.Name.ToLower(), likeTerm) ||
                    EF.Functions.Like(l.Country.ToLower(), likeTerm));
            }

            var totalCount = await query.CountAsync();

            var results = await query
                .OrderByDescending(l => l.Id) 
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ProjectTo<LocationDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            return new PagedResult<LocationDTO> { Result = results, TotalCount = totalCount, Page = page, PageSize = pageSize };
        }

        public async Task<List<LocationDTO>> GetFilteredLocationsAsync(string? country, string? region, bool includeInactive = false)
        {
            var query = _context.Locations.AsQueryable();

            if (!includeInactive)
            {
                query = query.Where(l => l.IsActive);
            }

            if (!string.IsNullOrEmpty(country))
            {
                query = query.Where(l => l.Country == country);
            }

            if (!string.IsNullOrEmpty(region))
            {
                query = query.Where(l => l.Region == region);
            }

            return await query
                .ProjectTo<LocationDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();
        }

        public override async Task<string> Delete(int id)
        {
            var location = await _context.Locations.FindAsync(id)
                ?? throw new UserException("Location not found");

            var isUsedByTender = await _context.Tenders.AnyAsync(t => t.LocationId == id);
            if (!isUsedByTender)
            {
                _context.Locations.Remove(location);
                await _context.SaveChangesAsync();
                return "Location deleted successfully.";
            }

            location.IsActive = false;
            await _context.SaveChangesAsync();
            return "Location is used by existing tenders and has been deactivated.";
        }

        public async Task<LocationDTO> Activate(int id)
        {
            var location = await _context.Locations.FindAsync(id)
                ?? throw new UserException("Location not found");

            location.IsActive = true;
            await _context.SaveChangesAsync();

            return _mapper.Map<LocationDTO>(location);
        }

        public async Task<LocationDTO> Deactivate(int id)
        {
            var location = await _context.Locations.FindAsync(id)
                ?? throw new UserException("Location not found");

            location.IsActive = false;
            await _context.SaveChangesAsync();

            return _mapper.Map<LocationDTO>(location);
        }

        public async Task<List<LocationStatsDTO>> GetLocationStatisticsAsync()
        {
            return await _context.Locations
                .Select(c => new LocationStatsDTO
                {
                    LocationId = c.Id,
                    LocationName = c.Name,
                    TenderCount = _context.Tenders.Count(t => t.LocationId == c.Id),
                    IsActive = c.IsActive
                })
                .OrderByDescending(c => c.TenderCount)
                .ToListAsync();
        }

        public async Task<LocationOverviewDTO> GetOverviewAsync()
        {
            return new LocationOverviewDTO
            {
                TotalLocations = await _context.Locations.CountAsync(),

                ActiveLocations = await _context.Locations
                    .CountAsync(l => l.IsActive),

                InactiveLocations = await _context.Locations
                    .CountAsync(l => !l.IsActive),

                LocationsWithTenders = await _context.Locations
                    .CountAsync(l => _context.Tenders.Any(t => t.LocationId == l.Id))
            };
        }
    }
}
