using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class LocationController : BaseController<LocationDTO, Location, LocationInsertRequest, LocationUpdateRequest>
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

        [Authorize(Roles = AppRoles.Admin)]
        [HttpGet("admin-search")]
        public async Task<IActionResult> GetAdminSearch([FromQuery] LocationSearchRequest request)
        {
            var result = await _locationService.GetAdminLocationsPagedAsync(request);
            return Ok(result);
        }

        [HttpGet("all")]
        public async Task<IActionResult> GetAll([FromQuery] LocationFilterRequest request)
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
        [Authorize(Roles = AppRoles.Admin)]

        [HttpPatch("{id}/activate")]
        public async Task<IActionResult> Activate(int id)
        {
            var location = await _locationService.Activate(id);
            return Ok(location);
        }
        [Authorize(Roles = AppRoles.Admin)]

        [HttpPatch("{id}/deactivate")]
        public async Task<IActionResult> Deactivate(int id)
        {
            var location = await _locationService.Deactivate(id);
            return Ok(location);
        }
        [Authorize(Roles = AppRoles.Admin)]

        [HttpGet("statistics")]
        public async Task<IActionResult> GetStatistics()
        {
            var statistics = await _locationService.GetLocationStatisticsAsync();
            return Ok(statistics);
        }
        [Authorize(Roles = AppRoles.Admin)]

        [HttpGet("overview")]
        public async Task<IActionResult> GetOverview()
        {
            var overview = await _locationService.GetOverviewAsync();
            return Ok(overview);
        }
    }
}
