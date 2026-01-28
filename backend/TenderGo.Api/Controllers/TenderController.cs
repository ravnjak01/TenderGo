using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Api.Database;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;

public class TenderController
   : BaseController<TenderDTO, TenderInsertRequest, TenderUpdateRequest>
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


}
