using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class CategoryController : BaseController<CategoryDTO, CategorySearchRequest, CategoryInsertRequest, CategoryUpdateRequest>
    {
        private readonly ICategoryService _categoryService;

        public CategoryController(
            ICategoryService categoryService,
            ILogger<CategoryController> logger)
            : base(categoryService, categoryService, logger)
        {
            _categoryService = categoryService;
        }

        // POST api/category (Samo Admin može dodavati)
        [Authorize(Roles = AppRoles.Admin)]
        [HttpPost]
        public override Task<IActionResult> Insert([FromBody] CategoryInsertRequest request)
        {
            return base.Insert(request);
        }

        // PATCH api/category/{id} (Samo Admin može azurirati)
        [Authorize(Roles = AppRoles.Admin)]
        [HttpPatch("{id:int}")]
        public override Task<IActionResult> Update(int id, [FromBody] CategoryUpdateRequest request)
        {
            return base.Update(id, request);
        }

        // DELETE api/category/{id} (Samo Admin može brisati)
        [Authorize(Roles = AppRoles.Admin)]
        [HttpDelete("{id:int}")]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }

        // PATCH api/category/{id}/activate
        [Authorize(Roles = AppRoles.Admin)]
        [HttpPatch("{id:int}/activate")]
        public async Task<IActionResult> Activate(int id)
        {
            var category = await _categoryService.Activate(id);
            return Ok(category);
        }

        // PATCH api/category/{id}/deactivate
        [Authorize(Roles = AppRoles.Admin)]
        [HttpPatch("{id:int}/deactivate")]
        public async Task<IActionResult> Deactivate(int id)
        {
            var category = await _categoryService.Deactivate(id);
            return Ok(category);
        }

        // GET api/category/statistics
        [Authorize(Roles = AppRoles.Admin)]
        [HttpGet("statistics")]
        public async Task<IActionResult> GetStatistics()
        {
            var stats = await _categoryService.GetCategoryStatisticsAsync();
            return Ok(stats);
        }
    }
}