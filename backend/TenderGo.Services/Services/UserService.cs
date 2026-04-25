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
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class UserService : IUserService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly TenderGoContext _context;
        private readonly TenderService _tenderService;

        public UserService(UserManager<ApplicationUser> userManager,TenderGoContext context, TenderService tenderService)
        {
            _userManager = userManager;
            _context = context;
            _tenderService = tenderService; 
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

        public async Task<bool> RateUserAsync(string ratedByUserId, RateUserDTO dto)
        {
            var tender = await _context.Tenders
                .FirstOrDefaultAsync(t => t.Id == dto.TenderId)
                ?? throw new NotFoundException("Tender not found", new { dto.TenderId });

            var state = _tenderService.CreateState(tender.Status);

            if (!state.CanRate())
                throw new UserException("Rating not allowed in current tender state.");

            if (tender.Status != TenderStatus.Awarded)
                throw new UserException("Tender is not completed yet.");

            var ratedUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == dto.RatedUserId)
                ?? throw new NotFoundException("User not found", new { dto.RatedUserId });

            var alreadyRated = await _context.Ratings.AnyAsync(r =>
                r.TenderId == dto.TenderId &&
                r.RatedByUserId == ratedByUserId &&
                r.RatedUserId == dto.RatedUserId);

            if (alreadyRated)
                throw new UserException("You already rated this user for this tender.");

            var rating = new Rating
            {
                RatedByUserId = ratedByUserId,
                RatedUserId = dto.RatedUserId,
                TenderId = dto.TenderId,
                Score = dto.Score,
                Comment = dto.Comment,
                CreatedAt = DateTime.UtcNow
            };

            _context.Ratings.Add(rating);

            // ⭐ update rating stats
            ratedUser.AverageRating =
                ((ratedUser.AverageRating * ratedUser.RatingCount) + dto.Score)
                / (ratedUser.RatingCount + 1);

            ratedUser.RatingCount++;

            await _context.SaveChangesAsync();

            return true;
        }
    }
}
