using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services;


public abstract class BaseController<T, TInsert, TUpdate>
    : ControllerBase where T:IHasId
{
    protected readonly IBaseService<T, TInsert, TUpdate> _service;
    private readonly ILogger<BaseController<T, TInsert, TUpdate>> _logger;

    protected BaseController(IBaseService<T, TInsert, TUpdate> service, ILogger<BaseController<T, TInsert, TUpdate>> logger)
    {
        _service = service;
        _logger = logger;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TenderDTO>> GetById(int id)
        => Ok(await _service.GetById(id));

    [HttpPost]
    public async Task<ActionResult<TenderDTO>> Insert(TInsert request)
    {
        var result = await _service.Insert(request);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, TUpdate request)
    {
        await _service.Update(id, request);
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        await _service.Delete(id);
        return NoContent();
    }
}
