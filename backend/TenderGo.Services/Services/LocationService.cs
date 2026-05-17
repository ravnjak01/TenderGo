using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class LocationService:ILocationService
    {
        private readonly TenderGoContext _context;
        public LocationService(TenderGoContext context)
        {
            _context = context;
        }

        public async Task<List<LocationDTO>> GetAllLocationsAsync()
        {
            return await _context.Locations
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
