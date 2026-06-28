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

        [Authorize(Roles =AppRoles.Admin)]
        [HttpPost]
        public override Task<IActionResult> Insert([FromBody] CategoryInsertRequest request) 
        {
            return base.Insert(request);
        }
        [Authorize(Roles = AppRoles.Admin)]

        [HttpGet("search")]
        public async Task<IActionResult> Search([FromQuery] CategorySearchRequest request) 
        {
            var result = await _categoryService.SearchAsync(request);
            return Ok(result);
        }
        [Authorize(Roles = AppRoles.Admin)]

        [HttpPatch("{id}")]
        public override Task<IActionResult> Update(int id, [FromBody] CategoryUpdateRequest request)
        {
            return base.Update(id, request);
        }
        [Authorize(Roles = AppRoles.Admin)]

        [HttpDelete("{id}")]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }

        [Authorize(Roles = AppRoles.Admin)]
        [HttpPatch("{id}/activate")]

        public async Task<IActionResult> Activate(int id) 
        {
            var category = await _categoryService.Activate(id);

            return Ok(category);
        }

        [Authorize(Roles = AppRoles.Admin)]

        [HttpPatch("{id}/deactivate")]
        public async Task<IActionResult> Deactivate(int id)
        {
            var category = await _categoryService.Deactivate(id);

            return Ok(category);


        }
        [Authorize(Roles = AppRoles.Admin)]

        [HttpGet("statistics")]
        public async Task<IActionResult> GetStatistics() 
        {
            var stats = await _categoryService.GetCategoryStatisticsAsync();
            return Ok(stats);
        }
    }
}