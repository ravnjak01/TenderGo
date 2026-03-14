using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface IUserService
    {   
            Task<bool> ChangePasswordAsync(string userId, ChangePasswordDTO dto);

            Task UpdateProfileAsync(string userId, UpdateProfileDTO dto);
             Task<UserDTO> GetProfileAsync(string id);


    }
}
