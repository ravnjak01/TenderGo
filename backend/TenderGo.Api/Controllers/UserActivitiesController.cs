using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Services.Interfaces;

namespace TenderGo.Controllers;

[Authorize]
[ApiController]
[Route("api/user-activities")]
public class UserActivitiesController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ITenderService _tenderService;

    public UserActivitiesController(IAuthService authService, ITenderService tenderService)
    {
        _authService = authService;
        _tenderService = tenderService;
    }

    [HttpPost("log")]
    public async Task<IActionResult> LogActivity([FromBody] ActivityLogDto dto)
    {
        var userId = _authService.GetCurrentUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var logged = await _tenderService.LogUserActivityAsync(
            dto.ActivityType,
            dto.TenderId,
            dto.SearchQuery,
            dto.DurationSeconds);

        return Ok(logged);
    }
}

public class ActivityLogDto
{
    public string ActivityType { get; set; } = null!;
    public int? TenderId { get; set; }
    public string? SearchQuery { get; set; }
    public int? DurationSeconds { get; set; }
}