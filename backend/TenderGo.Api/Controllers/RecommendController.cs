using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Services.Interfaces;

namespace TenderGo.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class RecommendController : ControllerBase
{
    private readonly IRecommendationService _recommendationService;

    public RecommendController(IRecommendationService recommendationService)
    {
        _recommendationService = recommendationService;
    }

    [HttpGet("similar/{tenderId:int}")]
    public async Task<IActionResult> GetSimilar(int tenderId, [FromQuery] int topN = 10)
    {
        var result = await _recommendationService.GetSimilarAsync(tenderId, topN);

        if (result is null)
            return NotFound($"Tender {tenderId} not found.");

        return Ok(result.Recommendations);
    }

    [HttpGet("for-user")]
    public async Task<IActionResult> GetForCurrentUser([FromQuery] int topN = 10)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        if (userId is null)
            return Unauthorized();

        var result = await _recommendationService.GetForCurrentUserAsync(userId, topN);

        return Ok(result.Recommendations);
    }
}