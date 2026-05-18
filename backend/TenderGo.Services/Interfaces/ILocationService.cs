using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Interfaces
{
    public interface ILocationService : IReadService<LocationDTO>, IWriteService<LocationDTO, LocationInsertRequest, LocationUpdateRequest>
    {
        Task<List<LocationDTO>> GetFilteredLocationsAsync(string? country, string? region);
    }
}
