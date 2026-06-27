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
    public class CategoryController : BaseController<CategoryDTO, Category, CategoryInsertRequest, CategoryUpdateRequest>
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
        public override Task<IActionResult> Insert([FromBody] CategoryInsertRequest request) 
        {
            return base.Insert(request);
        }

        [HttpGet("search")]
        public async Task<IActionResult> Search([FromQuery] CategorySearchRequest request) 
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
        public async Task<IActionResult> Activate(int id) 
        {
            var category = await _categoryService.Activate(id);

            return Ok(category);
        }

        [HttpPatch("{id}/deactivate")]
        public async Task<IActionResult> Deactivate(int id)
        {
            var category = await _categoryService.Deactivate(id);

            return Ok(category);


        }
        [HttpGet("statistics")]
        public async Task<IActionResult> GetStatistics() 
        {
            var stats = await _categoryService.GetCategoryStatisticsAsync();
            return Ok(stats);
        }
    }
}