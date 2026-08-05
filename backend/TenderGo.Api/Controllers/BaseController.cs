using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;

public abstract class BaseController<TModel,TSearch,TInsert, TUpdate>
    : ControllerBase
    where TModel : class
   where TSearch : PagedSearchRequest
{
    protected readonly IReadService<TModel, TSearch> _readService;
    protected readonly IWriteService<TModel ,TInsert, TUpdate> _writeService;
    private readonly ILogger<BaseController<TModel, TSearch, TInsert, TUpdate>> _logger;

    protected BaseController(
              IReadService<TModel, TSearch> readService,
              IWriteService<TModel, TInsert, TUpdate> writeService,
              ILogger<BaseController<TModel, TSearch, TInsert, TUpdate>> logger)
    {
        _readService = readService;
        _writeService = writeService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] TSearch request) 
        => Ok(await _readService.Get(request));

    [HttpGet("{id:int}")]
    public virtual async Task<IActionResult> GetById(int id) 
        => Ok(await _readService.GetById(id));

    [HttpPost]
    public virtual async Task<IActionResult> Insert([FromBody] TInsert request)
    {
        var result = await _writeService.Insert(request);

        return Ok(result);
    }

    [HttpPatch("{id}")]
    public virtual async Task<IActionResult> Update(int id, [FromBody] TUpdate request) 
    {
        await _writeService.Update(id, request);

        return Ok();
    }

    [HttpDelete("{id}")]
    public virtual async Task<IActionResult> Delete(int id)
    {
        await _writeService.Delete(id);

        return Ok();
    }
}