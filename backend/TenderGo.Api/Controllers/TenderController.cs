using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Api.Database;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;



[Route("api/tender")]
public class TenderController
   : BaseController<TenderDTO, Tender,TenderInsertRequest, TenderUpdateRequest>
{

    private readonly ITenderService _tenderService;

    public TenderController(ITenderService tenderService, ILogger<TenderController> logger,IAuthService authservice)
        : base(tenderService, logger)
    {
        _tenderService = tenderService;
    }




    [HttpGet("active")]
    public async Task<ActionResult<List<TenderDTO>>> GetActive()
     => Ok(await _tenderService.GetActiveTenders());

    [HttpGet("closed")]
    public async Task<ActionResult<List<TenderDTO>>> GetClosed()
        => Ok(await _tenderService.GetClosedTenders());

    [HttpGet("category/{id}")]
    public async Task<ActionResult<List<TenderDTO>>> GetByCategory(int id)
        => Ok(await _tenderService.GetTendersByCategory(id));

    [Authorize(Roles = "User,Admin")]
    [HttpPatch("{tenderId}/close")]
    public async Task<IActionResult> CloseTender(int tenderId)
    {
        await _tenderService.CloseTender(tenderId);
        return NoContent();
    }
    [HttpPatch("{tenderId}/bids/{bidId}/accept")]
    public async Task<IActionResult> AcceptBid(int tenderId, int bidId)
    {
        await _tenderService.AcceptBid(tenderId, bidId);
        return NoContent();
    }

}
