using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
            var result = await _authService.RegisterAsync(dto);
            if (result.Succeeded)
            {
                return Ok(new { Message = "User registered successfully" });
            }
            return BadRequest(result.Errors);
        }
        [AllowAnonymous]
        [HttpPost("login")]
            public async Task<IActionResult> Login([FromBody] LoginRequest dto)
            {
                var result = await _authService.LoginAsync(dto);
            if (result == null)
                return Unauthorized("Invalid email or password");

            return Ok(new
            {
                Message="Login successfull",
                Data=result
                
            });
        }

    }
}
