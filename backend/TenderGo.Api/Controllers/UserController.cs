using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Route("api/users")]
    [Authorize]
    public class UserController : ControllerBase
    {
        private readonly IUserService _userService;

        public UserController(IUserService userService)
        {
            _userService = userService;
        }
        [HttpGet("{id}")]
        public async Task<ActionResult<UserPublicDTO>> GetUserPublic(string id)
        {
            var result = await _userService.GetPublicByIdAsync(id);

            if (result == null)
                return NotFound("User not found.");

            return Ok(result);
        }

        [HttpPost("rate")]
        [Authorize]
        public async Task<IActionResult> RateUser([FromBody] RateUserRequest dto)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            await _userService.RateUserAsync(userId, dto);
            return Ok(new { message = "Rating submitted successfully." });
        }

        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized("User ID not found in token.");
            }

            await _userService.UpdateProfileAsync(userId, request);

            return Ok(new { message = "Profile updated successfully." });
        }


    }
}
