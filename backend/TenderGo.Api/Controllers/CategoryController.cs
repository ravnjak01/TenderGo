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
    [Authorize(Roles = AppRoles.Admin)]
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
    }
}
