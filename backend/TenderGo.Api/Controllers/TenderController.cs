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
   : BaseController<TenderDTO, Tender, TenderInsertRequest, TenderUpdateRequest>
{
    private readonly ITenderService _tenderService;
    private readonly IAuthService _authService;

    public TenderController(ITenderService tenderService, ILogger<TenderController> logger, IAuthService authservice)
        : base(tenderService, tenderService, logger)
    {
        _tenderService = tenderService;
        _authService = authservice;
    }

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] TenderSearchRequest request)
    {
        var result = await _tenderService.SearchAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    public override async Task<IActionResult> GetById(int id)
    {
        var result = await _tenderService.GetById(id);
        return Ok(result);
    }

    [HttpPost("toggle/{tenderId}")]
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

    [HttpGet("active")]
    public async Task<IActionResult> GetActive([FromQuery]  PagedSearchRequest request)
        => Ok(await _tenderService.GetActiveTenders(request));

    [HttpGet("closed")]
    public async Task<IActionResult> GetClosed([FromQuery] PagedSearchRequest request)
        => Ok(await _tenderService.GetClosedTenders(request));

    [HttpGet("cancelled")]
    public async Task<IActionResult> GetCancelled([FromQuery] PagedSearchRequest request)
        => Ok(await _tenderService.GetCancelledTenders(request));

    [HttpGet("category/{id}")]
    public async Task<IActionResult> GetByCategory(int id, [FromQuery] PagedSearchRequest request)
        => Ok(await _tenderService.GetTendersByCategory(id,request));

    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetByUser(string userId,[FromQuery] PagedSearchRequest request)
    {
        var tenders = await _tenderService.GetTendersByUser(userId,request);
        return Ok(tenders);
    }

    [HttpPatch("{id}/cancel")]
    public async Task<IActionResult> Cancel(int id, [FromBody] TenderCancelRequest request)
    {
        var result = await _tenderService.Cancel(id,request);
        return Ok(result);
    }

    [HttpPatch("{id}/award/{bidId}")]
    public async Task<IActionResult> Award(int id, int bidId)
    {
        var result = await _tenderService.Award(id, bidId);
        return Ok(result);
    }

    [HttpGet("{id}/allowedActions")]
    public async Task<IActionResult> AllowedActions(int id)
    {
        var actions = await _tenderService.AllowedActions(id);
        return Ok(actions);
    }
}