using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class LocationController : BaseController<LocationDTO, LocationSearchRequest, LocationInsertRequest, LocationUpdateRequest>
    {
        private readonly ILocationService _locationService;

        public LocationController(
            ILocationService locationService,
            ILogger<LocationController> logger)
            // locationService se prosljeđuje i kao IReadService i kao IWriteService
            : base(locationService, locationService, logger)
        {
            _locationService = locationService;
        }

        // POST api/location (Samo Admin može dodavati)
        [Authorize(Roles = AppRoles.Admin)]
        [HttpPost]
        public override Task<IActionResult> Insert([FromBody] LocationInsertRequest request)
        {
            return base.Insert(request);
        }

        // PUT api/location/{id} (Samo Admin može mijenjati)
        [Authorize(Roles = AppRoles.Admin)]
        [HttpPatch("{id:int}")]
        public override Task<IActionResult> Update(int id, [FromBody] LocationUpdateRequest request)
        {
            return base.Update(id, request);
        }

        // DELETE api/location/{id} (Samo Admin može brisati)
        [Authorize(Roles = AppRoles.Admin)]
        [HttpDelete("{id:int}")]
        public override async Task<IActionResult> Delete(int id)
        {
            // Pozivamo custom Delete iz LocationService koji vraća poruku o obrisanoj/deaktiviranoj lokaciji
            var message = await _locationService.Delete(id);
            return Ok(new { message });
        }

        // GET api/location/all - Pomoćni endpoint bez paginacije (za dropdown opcije i sl.)
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

        // PATCH api/location/{id}/activate
        [Authorize(Roles = AppRoles.Admin)]
        [HttpPatch("{id:int}/activate")]
        public async Task<IActionResult> Activate(int id)
        {
            var location = await _locationService.Activate(id);
            return Ok(location);
        }

        // PATCH api/location/{id}/deactivate
        [Authorize(Roles = AppRoles.Admin)]
        [HttpPatch("{id:int}/deactivate")]
        public async Task<IActionResult> Deactivate(int id)
        {
            var location = await _locationService.Deactivate(id);
            return Ok(location);
        }

        // GET api/location/statistics
        [Authorize(Roles = AppRoles.Admin)]
        [HttpGet("statistics")]
        public async Task<IActionResult> GetStatistics()
        {
            var statistics = await _locationService.GetLocationStatisticsAsync();
            return Ok(statistics);
        }

        // GET api/location/overview
        [Authorize(Roles = AppRoles.Admin)]
        [HttpGet("overview")]
        public async Task<IActionResult> GetOverview()
        {
            var overview = await _locationService.GetOverviewAsync();
            return Ok(overview);
        }
    }
}