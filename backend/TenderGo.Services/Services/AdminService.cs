using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class AdminService : IAdminService
    {
        public Task<bool> BanUserAsync(string userId, string reason)
        {
            throw new NotImplementedException();
        }

        public Task<IEnumerable<UserDTO>> GetAllUsersAsync()
        {
            throw new NotImplementedException();
        }

        public Task<bool> UnbanUserAsync(string userId)
        {
            throw new NotImplementedException();
        }
    }
}
