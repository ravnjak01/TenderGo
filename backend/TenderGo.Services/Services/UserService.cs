using AutoMapper;
using AutoMapper.QueryableExtensions;
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
        private readonly IImageService _imageService;
        private readonly IMapper _mapper;
        private readonly IAuthService _authService;


        public UserService(UserManager<ApplicationUser> userManager,TenderGoContext context, ITenderService tenderService,IAuthService authService,IImageService imageService,IMapper mapper)
        {
            _userManager = userManager;
            _context = context;
            _tenderService = tenderService;
            _imageService = imageService;
            _mapper = mapper;
            _authService = authService;
        }


        public async Task<bool> ChangePasswordAsync(ChangePasswordRequest dto)
        {
            var userId = _authService.GetCurrentUserId();

            var user = await _userManager.FindByIdAsync(userId)
                ?? throw new NotFoundException("User not found", new { User = "User", Id = userId });

            var result = await _userManager.ChangePasswordAsync(
                user,
                dto.CurrentPassword,
                dto.NewPassword
            );

            if (!result.Succeeded)
            {
                var errorMessage = string.Join(" ", result.Errors.Select(e => e.Description));
                throw new UserException(errorMessage);
            }

            return true;
        }
        public async Task<UserPublicDTO> GetPublicByIdAsync(string id)
        {
            var response = await _context.Users
                .Where(u => u.Id == id)
                .Select(u => new UserPublicDTO
                {
                    Id = u.Id,
                    UserName = u.UserName,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    Location = u.Address != null
                        ? u.Address.City + ", " + u.Address.Country
                        : "No location",
                    ProfileImageUrl = u.ProfileImageUrl,

                    Rating = u.AverageRating,
                    ReviewCount = u.RatingCount,

                    TenderCount = u.CreatedTenders.Count(),
                    BidsCount = _context.Bids.Count(b => b.SubmittedByUserId == u.Id)
                })
                .FirstOrDefaultAsync()
                ?? throw new NotFoundException("User not found", new { User = "User", Id = id });

            return response;
        }
        public async Task UpdateProfileAsync(string userId, UpdateProfileRequest request)
        {
            var currentUserId = _authService.GetCurrentUserId();
            if (currentUserId != userId)
            {
                throw new ForbiddenException("You can only update your own profile.");

            }

            var user = await _context.Users
                      .FirstOrDefaultAsync(u => u.Id == userId)
                  ?? throw new NotFoundException("User not found", new { User = "User", Id = userId });


            if (!string.IsNullOrWhiteSpace(request.FirstName))
            {
                user.FirstName = request.FirstName;
            }

            if (!string.IsNullOrWhiteSpace(request.LastName))
            {
                user.LastName = request.LastName;
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

            user.UpdatedAt = DateTime.UtcNow;
            user.UpdatedBy = currentUserId;
            var result=await _userManager.UpdateAsync(user);

            if(!result.Succeeded)
            {
                var errorMessage = string.Join(" ", result.Errors.Select(e => e.Description));

                throw new UserException(errorMessage);
            }


        }

        public async Task<bool> RateUserAsync(string currentUserId, RateUserRequest dto)
        {
            if (dto.Score < 1 || dto.Score > 5)
                throw new UserException("Rating must be between 1 and 5");
            var tender = await _context.Tenders
                .Include(t => t.Bids)
                .FirstOrDefaultAsync(t => t.Id == dto.TenderId)
                ?? throw new NotFoundException("Tender not found", new { dto.TenderId });

            var state = _tenderService.CreateState(tender.Status);

            if (!state.CanRate())
                throw new UserException("Rating not allowed in current tender state.");

            var winningBid = tender.Bids
                .FirstOrDefault(b => b.Id == tender.WinningBidId) ??
                tender.Bids.FirstOrDefault(b => b.Status == ApplicationStatus.Accepted)
                ?? throw new UserException("Winning bid not found.");

            if (tender.Status != TenderStatus.Awarded &&
                winningBid.Status != ApplicationStatus.Accepted)
                throw new UserException("Tender is not completed yet.");

            if (dto.RatedUserId == currentUserId)
                throw new UserException("You cannot rate yourself.");

            var isTenderOwner = tender.CreatedByUserId == currentUserId;
            var isWinningBidder = winningBid.SubmittedByUserId == currentUserId;

            if (!isTenderOwner && !isWinningBidder)
                throw new UserException("Only tender participants can rate user.");

            if (isTenderOwner && dto.RatedUserId != winningBid.SubmittedByUserId)
                throw new UserException("Tender owner can only rate the winning bidder.");

            if (isWinningBidder && dto.RatedUserId != tender.CreatedByUserId)
                throw new UserException("Winning bidder can only rate the tender owner.");

        

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

        public async Task<List<ReviewDTO>> GetReviewsByUserIdAsync(string userId)
{
    var userExists = await _context.Users.AnyAsync(u => u.Id == userId);
    if (!userExists)
    {
        throw new NotFoundException("User not found", new { User = "User", Id = userId });
    }

    var reviews = await _context.Ratings
        .Where(r => r.RatedUserId == userId)
        .OrderByDescending(r => r.CreatedAt) 
        .Select(r => new ReviewDTO
        {
            Rating = r.Score,
            Comment = r.Comment,
            CreatedAt = r.CreatedAt,
            TenderId = r.TenderId,
            
            ReviewerName = _context.Users
                .Where(u => u.Id == r.RatedByUserId)
                .Select(u => u.FirstName + " " + u.LastName)
                .FirstOrDefault() ?? "Anonimni korisnik",

            TenderTitle = _context.Tenders
                .Where(t => t.Id == r.TenderId)
                .Select(t => t.Title)
                .FirstOrDefault() ?? "Nepoznat tender"
        })
        .ToListAsync();

    return reviews;
}

    }
}
