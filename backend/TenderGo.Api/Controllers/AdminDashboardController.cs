using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Route("api/admin/dashboard")]
    [Authorize(Roles = AppRoles.Admin)]
    public class AdminDashboardController : ControllerBase
    {
        private readonly IAdminDashboardService _adminDashboardService;

        public AdminDashboardController(IAdminDashboardService adminDashboardService)
        {
            _adminDashboardService = adminDashboardService;
        }

        [HttpGet]
        public async Task<IActionResult> GetDashboard() 
        {
            var dashboard = await _adminDashboardService.GetDashboardAsync();
            return Ok(dashboard);
        }

        [HttpGet("recent-activities")]
        public async Task<IActionResult> GetRecentActivities() 
        {
            var recentActivities = await _adminDashboardService.GetRecentActivitiesAsync();
            return Ok(recentActivities);
        }
    }
}