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
    public class LocationService : BaseService<LocationDTO, Location,LocationSearchRequest, LocationInsertRequest, LocationUpdateRequest>, ILocationService
    {
        private readonly IAuthService _authService;
        protected readonly ILogger<LocationService> _logger;
        protected readonly IServiceProvider _serviceProvider;

        public LocationService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor, IAuthService authService, ILogger<LocationService> logger, IServiceProvider serviceProvider) : base(context, mapper, httpContextAccessor)
        {
            _logger = logger;
            _authService = authService;
            _serviceProvider = serviceProvider;
        }

        protected override IQueryable<Location> ApplyFilter(IQueryable<Location> query, LocationSearchRequest request)
        {
            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = $"%{request.SearchTerm.ToLower()}%";
                query = query.Where(l =>
                    EF.Functions.Like(l.Name.ToLower(), term) ||
                    EF.Functions.Like(l.Country.ToLower(), term) ||
                    (l.Region != null && EF.Functions.Like(l.Region.ToLower(), term))
                );
            }


            var isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (!isAdmin)
            {
                query = query.Where(l => l.IsActive);
            }
            else
            {
                if (request.IsActive.HasValue)
                {
                    query = query.Where(l => l.IsActive == request.IsActive.Value);
                }
            }

            return query.OrderBy(l => l.Country).ThenBy(l => l.Name);
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
                ?? throw new NotFoundException("Location",id);

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
                         ?? throw new NotFoundException("Location", id);

            location.IsActive = true;
            await _context.SaveChangesAsync();

            return _mapper.Map<LocationDTO>(location);
        }

        public async Task<LocationDTO> Deactivate(int id)
        {
            var location = await _context.Locations.FindAsync(id)
                           ?? throw new NotFoundException("Location", id);

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
