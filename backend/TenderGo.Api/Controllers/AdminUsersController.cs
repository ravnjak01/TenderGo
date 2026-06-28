using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Route("api/admin/users")]
    [Authorize(Roles = AppRoles.Admin)]
    public class AdminUsersController : ControllerBase
    {
        private readonly IUserAdminService _adminUserService;

        public AdminUsersController(IUserAdminService adminUserService)
        {
            _adminUserService = adminUserService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _adminUserService.GetAllUsersAsync();
            return Ok(users);
        }

        [HttpGet("search")]
        public async Task<IActionResult> SearchUsers([FromQuery] AdminUserSearchRequest request)
        {
            var users = await _adminUserService.SearchAsync(request);
            return Ok(users);
        }

        [HttpPost("{userId}/ban")]
        public async Task<IActionResult> BanUser(string userId, [FromBody] BanRequest reason)
        {
            if (string.IsNullOrWhiteSpace(reason.Reason))
                return BadRequest("Ban reason is required."); 

            var result = await _adminUserService.BanUserAsync(userId, reason);

            if (!result)
                return NotFound($"User with ID '{userId}' not found.");

            return Ok(); 
        }

        [HttpPost("{userId}/unban")]
        public async Task<IActionResult> UnbanUser(string userId)
        {
            var result = await _adminUserService.UnbanUserAsync(userId);

            if (!result)
                return NotFound($"User with ID '{userId}' not found.");

            return Ok();
        }

        [HttpPut("{userId}/reset-password")]
        public async Task<IActionResult> AdminResetPassword(string userId, [FromBody] AdminResetPasswordRequest request)
        {
            await _adminUserService.AdminResetPasswordAsync(userId, request.NewPassword);
            return Ok();
        }
    }
}