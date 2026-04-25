using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class UserService : IUserService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly TenderGoContext _context;

        public UserService(UserManager<ApplicationUser> userManager,TenderGoContext context)
        {
            _userManager = userManager;
            _context = context;
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

       public async Task<UserPublicDTO> GetPublicByIdAsync(string id)
        {
            var user = await _context.Users
                .Include(u => u.CreatedTenders)
                .Include(u => u.Address)
                .FirstOrDefaultAsync(u => u.Id == id);


            var roles = await _userManager.GetRolesAsync(user);

            return new UserPublicDTO
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                UserName = user.UserName,
                Location = user.Address != null
                    ? $"{user.Address.City}, {user.Address.Country}"
                    : null,
                Rating = user.AverageRating,
                ReviewCount = user.RatingCount,
                TenderCount = user.CreatedTenders.Count,
                BidsCount = _context.Bids.Count(b => b.SubmittedByUserId == user.Id)
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
