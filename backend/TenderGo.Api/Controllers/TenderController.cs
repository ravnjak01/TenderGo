using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Models.DTOs;
using TenderGo.Services.Interfaces;



[Route("api/tender")]
[Authorize]
public class TenderController
   : BaseController<TenderDTO, Tender,TenderInsertRequest, TenderUpdateRequest>
{

    private readonly ITenderService _tenderService;

    public TenderController(ITenderService tenderService, ILogger<TenderController> logger,IAuthService authservice)
        : base(tenderService, tenderService,logger)
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

    [HttpGet("user/{userId}")]
    public async Task<ActionResult<List<TenderDTO>>> GetByUser(string userId)
    {
        var tenders = await _tenderService.GetTendersByUser(userId);

        if (tenders == null || !tenders.Any())
            return NotFound(); 

        return Ok(tenders);
    }

    [Authorize(Roles = $"{AppRoles.Admin},{AppRoles.User}")]
    [HttpPatch("{tenderId}/close")]
    public async Task<IActionResult> CancelTender(int tenderId)
    {
        await _tenderService.CancelTender(tenderId);
        return NoContent();
    }


 

}
