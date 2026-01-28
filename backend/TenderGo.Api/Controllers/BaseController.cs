using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services;


[Authorize(Roles = "User")]
public abstract class BaseController<T,TDb, TInsert, TUpdate>
    : ControllerBase where T:IHasId
{
    protected readonly IBaseService<T,TDb, TInsert, TUpdate> _service;
    private readonly ILogger<BaseController<T,TDb, TInsert, TUpdate>> _logger;

    protected BaseController(IBaseService<T,TDb ,TInsert, TUpdate> service, ILogger<BaseController<T, TDb,TInsert, TUpdate>> logger)
    {
        _service = service;
        _logger = logger;
    }


    [HttpGet]
    public async Task<ActionResult<List<T>>> GetAll()
        => Ok(await _service.Get());

    [HttpGet("{id}")]
    public async Task<ActionResult<T>> GetById(int id)
        => Ok(await _service.GetById(id));

    [HttpPost]
    public async Task<ActionResult<T>> Insert(TInsert request)
    {
        var result = await _service.Insert(request);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPatch("{id}")]
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
