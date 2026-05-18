using AutoMapper;
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
    public async Task<List<LocationDTO>> GetFilteredLocationsAsync(string? country, string? region)
{
    var query = _context.Locations.AsQueryable();

    // 1. Ako je izabrana samo država, vrati sve regije i gradove za nju
    if (!string.IsNullOrEmpty(country))
    {
        query = query.Where(l => l.Country == country);
    }

    // 2. Ako je izabrana i specifična regija, dodatno suzi pretragu na gradove u toj regiji
    if (!string.IsNullOrEmpty(region))
    {
        query = query.Where(l => l.Region == region);
    }

    return await query
        .Select(l => new LocationDTO
        {
            Id = l.Id,
            Name = l.Name,
            Country = l.Country,
            Region = l.Region
        })
        .ToListAsync();
}
}
}