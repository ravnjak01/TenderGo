using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class CategoryController : BaseController<CategoryDTO, Category, CategoryDTO, CategoryUpdateRequest>
    {
        private readonly ICategoryService _categoryService;

        public CategoryController(
            ICategoryService categoryService,
            ILogger<CategoryController> logger)
            : base(categoryService, categoryService, logger) 
        {
            _categoryService = categoryService;
        }


        [HttpPost]
        public override Task<ActionResult<CategoryDTO>> Insert([FromBody] CategoryDTO request)
        {
            return base.Insert(request);
        }

        [HttpGet("search")]
        public async Task<ActionResult<PagedResult<CategoryDTO>>> Search([FromQuery] CategorySearchRequest request)
        {
            var result = await _categoryService.SearchAsync(request);
            return Ok(result);
        }

        [HttpPatch("{id}")]
        public override Task<IActionResult> Update(int id, [FromBody] CategoryUpdateRequest request)
        {
            return base.Update(id, request);
        }

        [HttpDelete("{id}")]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }

        [HttpPatch("{id}/activate")]
        public async Task<ActionResult<CategoryDTO>> Activate(int id)
        {
            var category = await _categoryService.Activate(id);
            return Ok(new { message = "Category activated successfully.", data = category });
        }

        [HttpGet("statistics")]
        public async Task<ActionResult<List<CategoryStatsDTO>>> GetStatistics()
        {
            return Ok(await _categoryService.GetCategoryStatisticsAsync());
        }
    }
}
