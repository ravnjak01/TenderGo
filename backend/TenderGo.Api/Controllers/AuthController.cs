using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{

    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }
        [AllowAnonymous]
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest dto)
        {
            await _authService.RegisterAsync(dto);
            return Ok(new { Message = "User registered successfully" });
        }
        [AllowAnonymous]
        [HttpPost("login")]
            public async Task<IActionResult> Login([FromBody] LoginRequest dto)
            {
            var result = await _authService.LoginAsync(dto);
            if (result == null)
                return Unauthorized(new { Message = "Invalid email or password" });

            return Ok(result);
        }

        [HttpPost("logout")]
        [Authorize]

        public async Task<IActionResult> Logout()
        {
            await _authService.LogoutAsync();
            return Ok(new { Message = "User logged out successfully" });
        }

        [AllowAnonymous]
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest model, CancellationToken cancellationToken)
        {

            try
            {
                var baseUrl = $"{Request.Scheme}://{Request.Host}";

                await _authService.ForgotPasswordAsync(model, baseUrl, HttpContext.RequestAborted);

                return Ok(new { message = " If an account with mentioned email exists,link with instructions was sent." });
            }
            catch (Exception)
            {
                return StatusCode(500, new { message = "There was an error during processing the request." });
            }
        }

        [AllowAnonymous]
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest model)
        {


            if (!ModelState.IsValid) return BadRequest(ModelState);

            var result = await _authService.ResetPasswordAsync(model);

            if (result.Succeeded)
            {
                return Ok(new { message = "Password was reset successfully." });
            }

            return BadRequest(result.Errors);

        }
        [Authorize]
        [HttpGet("me")]
        public async Task<ActionResult<UserDTO>> GetMe()
        {
            return await _authService.GetMyProfile();
        }

       


    }
}
