using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [ApiController]
    [Route("api/admin")]
    [Authorize(Roles = AppRoles.Admin)]
    public class AdminController : ControllerBase
    {
        private readonly IAdminService _adminService;

        public AdminController(IAdminService adminService)
        {
            _adminService = adminService;
        }

        [HttpGet("users")]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _adminService.GetAllUsersAsync();
            return Ok(users);
        }

        [HttpPost("users/{userId}/ban")]
        public async Task<IActionResult> BanUser(string userId, [FromBody] BanRequest reason)
        {
            if (string.IsNullOrWhiteSpace(reason.Reason))
                return BadRequest("Ban reason is required.");

            var result = await _adminService.BanUserAsync(userId, reason);

            if (!result)
                return NotFound($"User with ID '{userId}' not found or already deleted.");

            return Ok(new { message = $"User {userId} has been banned." });
        }

        [HttpPost("users/{userId}/unban")]
        public async Task<IActionResult> UnbanUser(string userId)
        {
            var result = await _adminService.UnbanUserAsync(userId);

            if (!result)
                return NotFound($"User with ID '{userId}' not found or already deleted.");

            return Ok(new { message = $"User {userId} has been unbanned." });
        }

        [HttpPut("users/{userId}/reset-password")]
        public async Task<IActionResult> AdminResetPassword(string userId, [FromBody] AdminResetPasswordRequest request)
        {
            await _adminService.AdminResetPasswordAsync(userId, request.NewPassword);

            return Ok(new { Message = "User password has been successfully reset by administrator." });
        }
    }


}