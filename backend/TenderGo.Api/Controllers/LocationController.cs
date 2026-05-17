using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]

    public class LocationController : Controller
    {
        private readonly ILocationService _locationService;

        public LocationController(ILocationService locationService)
        {
            _locationService = locationService;
        }

        [HttpGet("all")]
        public async Task<ActionResult<List<LocationDTO>>> GetAll()
        {
            var locations = await _locationService.GetAllLocationsAsync();
            return Ok(locations);
        }
    }
}
