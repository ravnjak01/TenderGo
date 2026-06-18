using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Interfaces
{
    public interface IUserAdminService
    {
        Task<bool> BanUserAsync(string userId, BanRequest reason);
        Task<bool> UnbanUserAsync(string userId);
        Task<IEnumerable<UserDTO>> GetAllUsersAsync();
        Task<PagedResult<UserDTO>> SearchAsync(AdminUserSearchRequest request);
        Task AdminResetPasswordAsync(string userId, string newPassword);
    }
}
