using AutoMapper;
using AutoMapper.QueryableExtensions;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
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
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class LocationService:BaseService<LocationDTO,Location, LocationInsertRequest, LocationUpdateRequest>,ILocationService
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
}
}
