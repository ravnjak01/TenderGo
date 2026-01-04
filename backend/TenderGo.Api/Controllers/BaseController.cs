using Microsoft.AspNetCore.Mvc;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [Route("api/[controller]")]
    public class BaseController<T> : ControllerBase where T : class
    {
        private readonly IBaseService<T> _service;
        private readonly ILogger<BaseController<T>> _logger;

        public BaseController(IBaseService<T> service, ILogger<BaseController<T>> logger)
        {
            _service = service;
            _logger = logger;
        }


        public async Task<IEnumerable<T>>Get()
        {
            return await _service.Get();
    }
    }
}
