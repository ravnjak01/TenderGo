using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface ILocationService
    {
        Task<List<LocationDTO>> GetAllLocationsAsync();
    }
}
