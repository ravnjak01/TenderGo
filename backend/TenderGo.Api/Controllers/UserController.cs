using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.DTOs;
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
    }
}
