using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Route("api/admin/report")]
    [Authorize(Roles = AppRoles.Admin)]
    public class AdminReportController : ControllerBase
    {
        private readonly IAdminReportService _adminReportService;

        public AdminReportController(IAdminReportService adminReportService)
        {
            _adminReportService = adminReportService;
        }

        [HttpGet("overview")]
        public async Task<ActionResult<AdminReportOverviewDTO>> GetReportOverview()
        {
            var overview = await _adminReportService.GetAdminReportOverview();
            return Ok(overview);
        }

        [HttpGet("tenders-by-location")]
        public async Task<IActionResult> DownloadTendersByLocationReport([FromQuery] AdminReportRequest request)
        {
            var pdfBytes = await _adminReportService.GenerateReportAsync(request);
            var from = request.From?.ToString("yyyyMMdd") ?? "start";
            var to = request.To?.ToString("yyyyMMdd") ?? "today";

            return File(pdfBytes, "application/pdf", $"tenders-by-location-{from}-{to}.pdf");
        }
    }
}
