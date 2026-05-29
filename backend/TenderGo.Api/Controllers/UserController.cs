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
        private readonly IAuthService _authService;

        public UserController(IUserService userService,IAuthService authService)
            {
                _userService = userService;
                _authService = authService;
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
                var userId = _authService.GetCurrentUserId();
                await _userService.UpdateProfileAsync(userId, request);

                return Ok(new { message = "Profile updated successfully." });
            }

            [HttpGet("{id}/reviews")]
            public async Task<IActionResult> GetUserReviews(string id)
            {
                var reviews = await _userService.GetReviewsByUserIdAsync(id);
                return Ok(reviews);
            }

        }
    }
