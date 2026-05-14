using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface IAuthService
    {

        Task<IdentityResult> RegisterAsync(RegisterRequest dto);
        Task<LoginResponseDto> LoginAsync(LoginRequest dto);
        Task LogoutAsync();

        Task ForgotPasswordAsync(ForgotPasswordRequest model, string baseUrl,CancellationToken cancellationToken);

        Task<IdentityResult> ResetPasswordAsync(ResetPasswordRequest model);
        string GenerateJwtToken(ApplicationUser user,IEnumerable<Claim>claims);
        string GetCurrentUserId();
        Task<UserDTO> GetMyProfile();
        bool IsInRole(string role);

    }
}
