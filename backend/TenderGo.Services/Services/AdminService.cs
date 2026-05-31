using AutoMapper;
using AutoMapper.QueryableExtensions;
using Azure.Core;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class AdminService : IAdminService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly TenderGoContext _context;
        private readonly IAuthService _authService;
        private readonly IMapper _mapper;
        public AdminService(UserManager<ApplicationUser> userManager, TenderGoContext context, IAuthService authService,IMapper mapper)
        {
            _userManager = userManager;
            _context = context;
            _mapper=mapper;
            _authService = authService;
        }


 protected virtual IQueryable<ApplicationUser> AddIncludes(IQueryable<ApplicationUser> query)
 {
    return query
    .Include(u=>u.Address)
    .Include(u=>u.RatingsReceived)
    .Include(u=>u.CreatedTenders);

 }

public async Task<IEnumerable<UserDTO>> GetAllUsersAsync()
{
    var finalQuery = from user in _context.Users
                     select new UserDTO
                     {
                         Id = user.Id,
                         Email = user.Email,
                         Username = user.UserName, 
                         FirstName = user.FirstName,
                         LastName = user.LastName,
                         Address = user.Address != null ? new AddressDTO 
                         { 
                         } : null,
                         Roles = (from userRole in _context.UserRoles
                                  join role in _context.Roles on userRole.RoleId equals role.Id
                                  where userRole.UserId == user.Id
                                  select role.Name).ToList(),
                         IsBanned = user.IsBanned,
                     };

    return await finalQuery.ToListAsync();
}
        public async Task<bool> BanUserAsync(string userId, BanRequest reason)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null ) return false;

            user.IsBanned = true;
            user.BanReason = reason.Reason;
            user.BannedAt = DateTime.UtcNow;

            await _userManager.SetLockoutEnabledAsync(user, true);
            await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.MaxValue);

            var result = await _userManager.UpdateAsync(user);
            return result.Succeeded;
        }

        public async Task<bool> UnbanUserAsync(string userId)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null) return false;

            user.IsBanned = false;
            user.BanReason = null;
            user.BannedAt = null;

            await _userManager.SetLockoutEndDateAsync(user, null);

            var result = await _userManager.UpdateAsync(user);
            return result.Succeeded;
        }

      
        public async Task AdminResetPasswordAsync(string userId, string newPassword)
        {
            if (!_authService.IsInRole(AppRoles.Admin))
                throw new ForbiddenException();

            var user = await _userManager.FindByIdAsync(userId);
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            await _userManager.ResetPasswordAsync(user, token, newPassword);
        }
    }
}