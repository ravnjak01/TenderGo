using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Models.DTOs;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;
using TenderGo.Services.Services;



[ApiController]
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


    [HttpGet("search")]
    public async Task<ActionResult<PagedResult<TenderDTO>>> Search([FromQuery] TenderSearchRequest request)
    {
        var result = await _tenderService.SearchAsync(request);
        return Ok(result);
    }

    [HttpGet("active")]
    public async Task<ActionResult<List<TenderDTO>>> GetActive()
     => Ok(await _tenderService.GetActiveTenders());

    [HttpGet("closed")]
    public async Task<ActionResult<List<TenderDTO>>> GetClosed()
        => Ok(await _tenderService.GetClosedTenders());

  

    [HttpGet("cancelled")]
    public async Task<ActionResult<List<TenderDTO>>> GetCancelled()
        => Ok(await _tenderService.GetCancelledTenders());

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



    [HttpPut("{id}/publish")]
    public async Task<ActionResult<TenderDTO>> Publish(int id)
    {
        var result= await _tenderService.Publish(id);
        return Ok(result);
    }

   
    [Authorize(Roles = $"{AppRoles.Admin},{AppRoles.User}")]
    [HttpPatch("{id}/cancel")]
    public async Task<ActionResult<TenderDTO>> Cancel(int id)
    {
        var result = await _tenderService.Cancel(id);
        return Ok(result);
    }

    [HttpPatch("{id}/award/{bidId}")]
    public async Task<ActionResult<TenderDTO>> Award(int id, int bidId)
    {

        var result = await _tenderService.Award(id, bidId);
        return Ok(result);
    }

    [HttpGet("{id}/allowedActions")]
    public async Task<List<string>> AllowedActions(int id)
    {
        return await _tenderService.AllowedActions(id);
    }

}
