using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ImagesController : ControllerBase
    {
        private readonly IImageService _imageService;

        public ImagesController(IImageService imageService)
        {
            _imageService = imageService;
        }

        [HttpPost("upload")]
        public async Task<IActionResult> UploadTenderImage(IFormFile file)
        {
          
            var imageDto = await _imageService.UploadImageAsync(file, "tenders");

            return Ok(imageDto);
        }

        [HttpDelete("{imageId:int}")]
        public async Task<IActionResult> DeleteImage(int imageId)
        {
            await _imageService.DeleteImageAsync(imageId);

            return NoContent();
        }
    }
}