using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Route("api/admin/tenders")]
    [Authorize(Roles = AppRoles.Admin)]
    public class AdminTendersController : ControllerBase
    {
        private readonly ITenderAdminService _tenderAdminService;

        public AdminTendersController(ITenderAdminService tenderAdminService)
        {
            _tenderAdminService = tenderAdminService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllTenders()
        {
            var tenders = await _tenderAdminService.GetAllTendersAsync();
            return Ok(tenders);
        }

        [HttpGet("search")]
        public async Task<IActionResult> SearchTenders([FromQuery] AdminTenderSearchRequest request)
        {
            var tenders = await _tenderAdminService.AdminSearchAsync(request);
            return Ok(tenders);
        }
    }
}
