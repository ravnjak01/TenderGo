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

        [Authorize]
        [HttpGet("me")]
        public async Task<ActionResult<MeResponseDTO>> GetMe()
        {
            return await _authService.GetMyProfile();
        }

    }
}
