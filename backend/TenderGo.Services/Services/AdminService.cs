using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class AdminService : IAdminService
    {
        private readonly UserManager<ApplicationUser> _userManager;

        public AdminService(UserManager<ApplicationUser> userManager)
        {
            _userManager = userManager;
        }

        public async Task<IEnumerable<UserDTO>> GetAllUsersAsync()
        {
            var users = await _userManager.Users
                .Where(u => u.IsDeleted == false)
                .Include(u => u.Address)
                .ToListAsync();

            var result = new List<UserDTO>();

            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);

                result.Add(new UserDTO
                {
                    Id = user.Id,
                    Email = user.Email,
                    Username = user.UserName,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Address = user.Address == null ? null : new AddressDTO
                    {
                        Street = user.Address.Street,
                        City = user.Address.City,
                        Country = user.Address.Country,
                        PostalCode = user.Address.PostalCode
                    },
                    Roles = roles.ToList()
                });
            }

            return result;
        }

        public async Task<bool> BanUserAsync(string userId, BanRequest reason)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null || user.IsDeleted == true) return false;

            user.IsBanned = true;
            user.BanReason = reason.Reason;
            user.BannedAt = DateTime.UtcNow;

            // Lock the account out indefinitely via Identity lockout
            await _userManager.SetLockoutEnabledAsync(user, true);
            await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.MaxValue);

            var result = await _userManager.UpdateAsync(user);
            return result.Succeeded;
        }

        public async Task<bool> UnbanUserAsync(string userId)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null || user.IsDeleted == true) return false;

            user.IsBanned = false;
            user.BanReason = null;
            user.BannedAt = null;

            // Lift the Identity lockout
            await _userManager.SetLockoutEndDateAsync(user, null);

            var result = await _userManager.UpdateAsync(user);
            return result.Succeeded;
        }
    }
}