using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Interfaces
{
    public interface IUserService
    {   
            Task<bool> ChangePasswordAsync( ChangePasswordRequest dto);

            Task UpdateProfileAsync(string userId, UpdateProfileRequest dto);
        Task<bool> RateUserAsync(string ratedByUserId, RateUserRequest dto);
        Task<UserPublicDTO> GetPublicByIdAsync(string id);
    


    }
}
