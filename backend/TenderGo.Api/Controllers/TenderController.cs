using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Models.DTOs;
using TenderGo.Services.Interfaces;

[ApiController]
[Route("api/tender")]
[Authorize]
public class TenderController
   : BaseController<TenderDTO, TenderSearchRequest, TenderInsertRequest, TenderUpdateRequest>
{
    private readonly ITenderService _tenderService;
    private readonly IAuthService _authService;

    public TenderController(ITenderService tenderService, ILogger<TenderController> logger, IAuthService authservice)
        : base(tenderService, tenderService, logger)
    {
        _tenderService = tenderService;
        _authService = authservice;
    }

    [HttpGet("admin")]
    [Authorize(Roles = AppRoles.Admin)] 
    public async Task<ActionResult<PagedResult<AdminTenderDTO>>> GetAdminTenders([FromQuery] TenderSearchRequest request)
    {
        var result = await _tenderService.GetAdminTendersAsync(request);
        return Ok(result);
    }

    [HttpPost("toggle/{tenderId:int}")]
    public async Task<IActionResult> ToggleBookmark(int tenderId)
    {
        string userId = _authService.GetCurrentUserId();

        bool isBookmarked = await _tenderService.ToggleBookmarkAsync(userId, tenderId);

        return Ok(isBookmarked);
    }

    [HttpGet("bookmarked")]
    public async Task<IActionResult> GetMyBookmarkedTenders([FromQuery] PagedSearchRequest request)
    {
        string userId = _authService.GetCurrentUserId();

        var tenders = await _tenderService.GetBookmarkedTendersAsync(userId,request);
        return Ok(tenders);
    }



    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetMyTenders(string userId,[FromQuery] PagedSearchRequest request)
    {
        var tenders = await _tenderService.GetMyTenders(userId,request);
        return Ok(tenders);
    }

    [HttpPatch("{id:int}/cancel")]
    public async Task<IActionResult> Cancel(int id, [FromBody] TenderCancelRequest request)
    {
        var result = await _tenderService.Cancel(id,request);
        return Ok(result);
    }

    [HttpPatch("{id:int}/award/{bidId}")]
    public async Task<IActionResult> Award(int id, int bidId)
    {
        var result = await _tenderService.Award(id, bidId);
        return Ok(result);
    }

    [HttpGet("{id:int}/allowedActions")]
    public async Task<IActionResult> AllowedActions(int id)
    {
        var actions = await _tenderService.AllowedActions(id);
        return Ok(actions);
    }
}