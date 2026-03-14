using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface IAdminService
    {
        Task<bool> BanUserAsync(string userId, string reason);
        Task<bool> UnbanUserAsync(string userId);
        Task<IEnumerable<UserDTO>> GetAllUsersAsync();

    }
}
