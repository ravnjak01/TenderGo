using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class UserService : IUserService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        public UserService(UserManager<ApplicationUser> userManager)
        {
            _userManager = userManager;
        }

        public async Task<bool> ChangePasswordAsync(string userId, ChangePasswordDTO dto)
        {
           var user = await _userManager.FindByIdAsync(userId)
                ?? throw new NotFoundException("User not found", new { User = "User", Id = userId });


            var result = await _userManager.ChangePasswordAsync(user, dto.CurrentPassword, dto.NewPassword);
            if (!result.Succeeded)
            {
                var errorMessage = string.Join(" ", result.Errors.Select(e => e.Description));
                throw new UserException(errorMessage);
            }
            return true;
        }

       public async Task<UserDTO> GetProfileAsync(string id)
        {
            var user = await _userManager.FindByIdAsync(id)
                ?? throw new NotFoundException("User not found", new { User = "User", Id = id });


            var roles = await _userManager.GetRolesAsync(user);
            return new UserDTO
            {
                Id = user.Id,
                Email = user.Email,
                Username = user.UserName,
                Address = user.Address != null ? new AddressDTO
                {
                    Street = user.Address.Street,
                    City = user.Address.City,
                    PostalCode = user.Address.PostalCode,
                    Country = user.Address.Country
                } : null,
                Roles = roles.ToList()
            };
        }

        public async Task UpdateProfileAsync(string userId, UpdateProfileDTO dto)
        {
            var user=await _userManager.FindByIdAsync(userId)
                ?? throw new NotFoundException("User not found", new { User = "User", Id = userId });


            if (dto.ProfileImageUrl != null)
            {
                user.ProfileImageUrl = dto.ProfileImageUrl;
            }
            if(dto.PhoneNumber != null)
            {
                user.PhoneNumber = dto.PhoneNumber;
            }
            if (dto.Address != null)
            {
                if (user.Address == null)
                {
                    var address = new Address
                    {
                        Street = dto.Address.Street,
                        City = dto.Address.City,
                        PostalCode = dto.Address.PostalCode,
                        Country = dto.Address.Country
                    };

                    user.Address = address;
                }
                else
                {
                    user.Address.Street = dto.Address.Street;
                    user.Address.City = dto.Address.City;
                    user.Address.PostalCode = dto.Address.PostalCode;
                    user.Address.Country = dto.Address.Country;
                }
            }

                var result=await _userManager.UpdateAsync(user);

            if(!result.Succeeded)
            {
                var errorMessage = string.Join(" ", result.Errors.Select(e => e.Description));

                throw new UserException(errorMessage);
            }


        }
    }
}
