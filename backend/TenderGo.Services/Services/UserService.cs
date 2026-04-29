using AutoMapper;
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
        private readonly ITenderService _tenderService;
        private readonly IAuthService _authService;
        private readonly IImageService _imageService;
        private readonly IMapper _mapper;


        public UserService(UserManager<ApplicationUser> userManager,TenderGoContext context, ITenderService tenderService,IAuthService authService,IImageService imageService,IMapper mapper)
        {
            _userManager = userManager;
            _context = context;
            _tenderService = tenderService;
            _authService = authService;
            _imageService = imageService;
            _mapper = mapper;
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
        .FirstOrDefaultAsync(u => u.Id == id)
        ?? throw new NotFoundException("User not found", new { User = "User", Id = id });

            var response = _mapper.Map<UserPublicDTO>(user);

            response.BidsCount = await _context.Bids.CountAsync(b => b.SubmittedByUserId == user.Id);

            return response;
        }

        public async Task UpdateProfileAsync(string userId, UpdateProfileRequest request)
        {
            var user = await _context.Users
                      .Include(u => u.Address) 
                      .FirstOrDefaultAsync(u => u.Id == userId)
                  ?? throw new NotFoundException("User not found", new { User = "User", Id = userId });


            bool hasFirstName = !string.IsNullOrWhiteSpace(request.FirstName);
            bool hasLastName = !string.IsNullOrWhiteSpace(request.LastName);

            if (hasFirstName || hasLastName)
            {
                bool isChangingFirstName = hasFirstName && request.FirstName != user.FirstName;
                bool isChangingLastName = hasLastName && request.LastName != user.LastName;

                if (isChangingFirstName || isChangingLastName)
                {
                    if (user.NameChangeCount >= 3)
                    {
                        throw new UserException("You have reached the maximum number of name changes (3).");
                    }

                    user.NameChangeCount++;

                    if (isChangingFirstName) user.FirstName = request.FirstName;
                    if (isChangingLastName) user.LastName = request.LastName;
                }
            }

            if (request.ImageBytes != null && request.ImageBytes.Length > 0)
            {
                var uploadResult = await _imageService.UploadImageAsync(request.ImageBytes, "profiles");

                user.ProfileImageUrl = uploadResult.ImageUrl;
            }
            if (request.Address != null)
            {
                if (user.Address == null)
                {
                    user.Address = new Address();
                }
                _mapper.Map(request.Address, user.Address);
            }

            var result=await _userManager.UpdateAsync(user);

            if(!result.Succeeded)
            {
                var errorMessage = string.Join(" ", result.Errors.Select(e => e.Description));

                throw new UserException(errorMessage);
            }


        }

        public async Task<bool> RateUserAsync(string currentUserId, RateUserDTO dto)
        {
            var tender = await _context.Tenders
                .Include(t => t.Bids)
                .FirstOrDefaultAsync(t => t.Id == dto.TenderId)
                ?? throw new NotFoundException("Tender not found", new { dto.TenderId });

            var state = _tenderService.CreateState(tender.Status);

            if (!state.CanRate())
                throw new UserException("Rating not allowed in current tender state.");

            if (tender.Status != TenderStatus.Awarded)
                throw new UserException("Tender is not completed yet.");

            var winningBid = tender.Bids
                .FirstOrDefault(b => b.Id == tender.WinningBidId)
                ?? throw new UserException("Winning bid not found.");

            if (winningBid.SubmittedByUserId != currentUserId)
                throw new UserException("Only winning bidder can rate user.");

            if (dto.RatedUserId == currentUserId)
                throw new UserException("You cannot rate yourself.");

            var ratedUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == dto.RatedUserId)
                ?? throw new NotFoundException("User not found", new { dto.RatedUserId });

            var alreadyRated = await _context.Ratings.AnyAsync(r =>
                r.TenderId == dto.TenderId &&
                r.RatedByUserId == currentUserId &&
                r.RatedUserId == dto.RatedUserId);

            if (alreadyRated)
                throw new UserException("You already rated this user for this tender.");

            var rating = new Rating
            {
                RatedByUserId = currentUserId,
                RatedUserId = dto.RatedUserId,
                TenderId = dto.TenderId,
                Score = dto.Score,
                Comment = dto.Comment,
                CreatedAt = DateTime.UtcNow
            };

            _context.Ratings.Add(rating);

            var totalScore = ratedUser.AverageRating * ratedUser.RatingCount;

            ratedUser.RatingCount++;

            ratedUser.AverageRating =
                (totalScore + dto.Score) / ratedUser.RatingCount;

            await _context.SaveChangesAsync();

            return true;
        }
    }
}
