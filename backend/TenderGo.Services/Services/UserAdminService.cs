using AutoMapper;
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
    public class UserAdminService : IUserAdminService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly TenderGoContext _context;
        private readonly IAuthService _authService;
        private readonly IMapper _mapper;
        public UserAdminService(UserManager<ApplicationUser> userManager, TenderGoContext context, IAuthService authService,IMapper mapper)
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

        public async Task<PagedResult<UserDTO>> GetAllUsersAsync(int page, int pageSize)
        {
            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var totalCount = await _context.Users.CountAsync();

            var users = await _context.Users
                .Include(u => u.Address)
                .OrderBy(u => u.LastName)
                .ThenBy(u => u.FirstName)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var userIds = users.Select(u => u.Id).ToList();
            var userRolesMap = await (from ur in _context.UserRoles
                                      join r in _context.Roles on ur.RoleId equals r.Id
                                      where userIds.Contains(ur.UserId)
                                      select new { ur.UserId, RoleName = r.Name })
                                     .GroupBy(x => x.UserId)
                                     .ToDictionaryAsync(g => g.Key, g => g.Select(x => x.RoleName).ToList());

            var results = users.Select(user => new UserDTO
            {
                Id = user.Id,
                Email = user.Email ?? string.Empty,
                Username = user.UserName ?? string.Empty,
                FirstName = user.FirstName,
                LastName = user.LastName,
                ProfileImageUrl = user.ProfileImageUrl,
                Address = user.Address != null ? new AddressDTO
                {
                    Country = user.Address.Country,
                    City = user.Address.City,
                    Street = user.Address.Street,
                    PostalCode = user.Address.PostalCode
                } : null,
                Roles = userRolesMap.ContainsKey(user.Id) ? userRolesMap[user.Id] : new List<string>(),
                IsBanned = user.IsBanned
            }).ToList();

            return new PagedResult<UserDTO>
            {
                Result = results,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }


        public async Task<PagedResult<UserDTO>> SearchAsync(AdminUserSearchRequest request)
        {
            var page = Math.Max(request.Page, 1);
            var pageSize = Math.Clamp(request.PageSize, 1, 100);

            var query = _context.Users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = request.SearchTerm.Trim().ToLower();
                var likeTerm = $"%{term}%";

                query = query.Where(u =>
                    (u.Email != null && EF.Functions.Like(u.Email.ToLower(), likeTerm)) ||
                    (u.UserName != null && EF.Functions.Like(u.UserName.ToLower(), likeTerm)) ||
                    EF.Functions.Like(u.FirstName.ToLower(), likeTerm) ||
                    EF.Functions.Like(u.LastName.ToLower(), likeTerm));
            }

            var totalCount = await query.CountAsync();

            var users = await query
                .Include(u => u.Address)
                .OrderBy(u => u.LastName)
                .ThenBy(u => u.FirstName)
                .ThenBy(u => u.Email)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var userIds = users.Select(u => u.Id).ToList();
            var userRolesMap = await (from ur in _context.UserRoles
                                      join r in _context.Roles on ur.RoleId equals r.Id
                                      where userIds.Contains(ur.UserId)
                                      select new { ur.UserId, RoleName = r.Name })
                                     .GroupBy(x => x.UserId)
                                     .ToDictionaryAsync(g => g.Key, g => g.Select(x => x.RoleName).ToList());

            var results = users.Select(user => new UserDTO
            {
                Id = user.Id,
                Email = user.Email ?? string.Empty,
                Username = user.UserName ?? string.Empty,
                FirstName = user.FirstName,
                LastName = user.LastName,
                ProfileImageUrl = user.ProfileImageUrl,
                Address = user.Address != null ? new AddressDTO
                {
                    Country = user.Address.Country,
                    City = user.Address.City,
                    Street = user.Address.Street,
                    PostalCode = user.Address.PostalCode
                } : null,
                Roles = userRolesMap.ContainsKey(user.Id) ? userRolesMap[user.Id] : new List<string>(),
                IsBanned = user.IsBanned
            }).ToList();

            return new PagedResult<UserDTO>
            {
                Result = results,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }
        public async Task<bool> BanUserAsync(string userId, BanRequest reason)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null ) return false;

            user.IsBanned = true;
            user.BanReason = reason.Reason;
            user.BannedAt = DateTime.UtcNow;

            var activeRefreshTokens=await _context.RefreshTokens
                .Where(rt=>rt.UserId == userId 
                && rt.IsRevoked == false
             && rt.Expires > DateTime.UtcNow).ToListAsync();

            foreach (var token in activeRefreshTokens)
            {
                token.RevokedAt = DateTime.UtcNow;
            }
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

            var user = await _userManager.FindByIdAsync(userId)
                ?? throw new NotFoundException("Korisnik nije pronađen.", new { UserId = userId });

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);

            var result = await _userManager.ResetPasswordAsync(user, token, newPassword);

            if (!result.Succeeded)
            {
                var errorMessages = string.Join("; ", result.Errors.Select(e => e.Description));
                throw new UserException($"Reset lozinke nije uspio: {errorMessages}");
            }
        }
    }
}
