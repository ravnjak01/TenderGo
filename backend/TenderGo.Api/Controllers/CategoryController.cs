using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CategoryController : BaseController<CategoryDTO, Category, CategoryDTO, CategoryDTO>
    {
        private readonly ICategoryService _categoryService;

        public CategoryController(
            ICategoryService categoryService,
            ILogger<CategoryController> logger)
            : base(categoryService, categoryService, logger) 
        {
            _categoryService = categoryService;
        }

        [Authorize(Roles = "Admin")]
        public override Task<ActionResult<CategoryDTO>> Insert([FromBody] CategoryDTO request)
        {
            return base.Insert(request);
        }

        [Authorize(Roles = "Admin")]
        public override Task<IActionResult> Update(int id, [FromBody] CategoryDTO request)
        {
            return base.Update(id, request);
        }

        [Authorize(Roles = "Admin")]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }
    }
}
