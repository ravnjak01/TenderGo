using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TenderGo.Models.DTOs;
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;

public abstract class BaseController<T, TDb, TInsert, TUpdate>
    : ControllerBase
    where T : class
    where TDb : class
{
    protected readonly IReadService<T> _readService;
    protected readonly IWriteService<T, TInsert, TUpdate> _writeService;
    private readonly ILogger<BaseController<T, TDb, TInsert, TUpdate>> _logger;

    protected BaseController(IWriteService<T, TInsert, TUpdate> writeService, IReadService<T> readService, ILogger<BaseController<T, TDb, TInsert, TUpdate>> logger)
    {
        _readService = readService;
        _writeService = writeService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] PagedResult<T> pagedResult) 
        => Ok(await _readService.Get(pagedResult));

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