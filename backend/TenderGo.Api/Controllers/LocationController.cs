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
    
        [HttpGet("all")]
        public async Task<ActionResult<List<LocationDTO>>> GetAll([FromQuery] LocationFilterRequest request)
        {
            var locations = await _locationService.GetFilteredLocationsAsync(request.Country, request.Region);
            return Ok(locations);
        }
    }
}
