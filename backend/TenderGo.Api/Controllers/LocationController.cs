using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]

    public class LocationController : BaseController<LocationDTO,Location,LocationInsertRequest,LocationUpdateRequest>
    {
        private readonly ILocationService _locationService;
        private readonly ILogger<LocationController> _logger;

        public LocationController(
            ILocationService locationService,
            ILogger<LocationController> logger)
            : base(locationService, locationService, logger) 
        {
            _locationService = locationService;
            _logger = logger;
        }

        [HttpGet("search")]
        public async Task<ActionResult<PagedResult<LocationDTO>>> Search([FromQuery] LocationSearchRequest request)
        {
            var result = await _locationService.SearchAsync(request);
            return Ok(result);
        }
    
        [HttpGet("all")]
        public async Task<ActionResult<List<LocationDTO>>> GetAll([FromQuery] LocationFilterRequest request)
        {
            if (!User.IsInRole(AppRoles.Admin))
            {
                request.IncludeInactive = false;
            }

            var locations = await _locationService.GetFilteredLocationsAsync(
                request.Country,
                request.Region,
                request.IncludeInactive
    );

            return Ok(locations);
        }

        [HttpPatch("{id}/activate")]
        public async Task<ActionResult<LocationDTO>> Activate(int id)
        {
            var location = await _locationService.Activate(id);
            return Ok(new { message = "Location activated successfully.", data = location });
        }

        [HttpPatch("{id}/deactivate")]
        public async Task<ActionResult<LocationDTO>> Deactivate(int id)
        {
            var location = await _locationService.Deactivate(id);
            return Ok(new { message = "Location deactivated successfully.", data = location });

        }
        [HttpGet("statistics")]
        public async Task<ActionResult<List<LocationStatsDTO>>> GetStatistics()
        {
            var statistics = await _locationService.GetLocationStatisticsAsync();
            return Ok(statistics);
        }

        [HttpGet("overview")]
        public async Task<ActionResult<LocationOverviewDTO>> GetOverview()
        {
            return Ok(await _locationService.GetOverviewAsync());
        }
    }
}
