using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services;


public abstract class BaseController<T,TDb, TInsert, TUpdate>
    : ControllerBase
    where T : class
    where TDb : class
{
    protected readonly IReadService<T> _readService;
    protected readonly IWriteService<T, TInsert, TUpdate> _writeService;
    private readonly ILogger<BaseController<T,TDb, TInsert, TUpdate>> _logger;

    protected BaseController(IWriteService<T, TInsert, TUpdate> writeService, IReadService<T> readService, ILogger<BaseController<T, TDb,TInsert, TUpdate>> logger)
    {
        _readService = readService;
        _writeService = writeService;
        _logger = logger;
    }


    [HttpGet]
    public async Task<ActionResult<PagedResult<T>>> GetAll([FromQuery] PagedResult<T> pagedResult)
        => Ok(await _readService.Get( pagedResult));

    [HttpGet("{id}")]
    public async Task<ActionResult<T>> GetById(int id)
        => Ok(await _readService.GetById(id));

    [HttpPost]
    public async Task<ActionResult<T>> Insert(TInsert request)
    {
        var result = await _writeService.Insert(request);
        return Ok(result);
    }

    [HttpPatch("{id}")]
    public virtual async Task<IActionResult> Update(int id, TUpdate request)
    {
        await _writeService.Update(id, request);
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        await _writeService.Delete(id);
        return NoContent();
    }
}
