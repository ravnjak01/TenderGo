using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Services.Interfaces;

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
        try
        {
            var imageDto = await _imageService.UploadImageAsync(file, "tenders");

            return Ok(new { imageUrl = imageDto.ImageUrl });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex) 
        {
            return StatusCode(500, ex.Message); 
        }
    }

    [HttpDelete]
    public IActionResult DeleteImage(string path)
    {
        _imageService.DeleteImage(path);
        return Ok();
    }
}