using AutoMapper;
using AutoMapper.QueryableExtensions;
using EasyNetQ;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.NetworkInformation;
using System.Reflection.Metadata;
using System.Security.Claims;
using System.Text;
using System.Threading.Channels;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;
using TenderGo.Services.StateMachines.TenderStates;

namespace TenderGo.Services.Services
{
    public class TenderService : BaseService<TenderDTO, Tender, TenderInsertRequest, TenderDTO>, ITenderService
    {

        private readonly IAuthService _authService;
        protected readonly ILogger<TenderService> _logger;
        protected readonly IServiceProvider _serviceProvider;
        protected readonly IImageService _imageService;
        protected readonly IBidService _bidService;

        public TenderService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor, IAuthService authService, ILogger<TenderService> logger, IServiceProvider serviceProvider, IImageService imageService, IBidService bidService) : base(context, mapper, httpContextAccessor)
        {
            _logger = logger;
            _authService = authService;
            _serviceProvider = serviceProvider;
            _imageService = imageService;
            _bidService = bidService;
        }

        protected override IQueryable<Tender> AddIncludes(IQueryable<Tender> query)
        {
            return query
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Bids)
                .Include(t => t.Images)
                .Include(t=>t.Location);
        }

        public async Task<bool> ToggleBookmarkAsync(string userId, int tenderId)
{
    var tenderExists = await _context.Tenders.AnyAsync(t => t.Id == tenderId);
    if (!tenderExists)
    {
        throw new NotFoundException("Tender not found", new { TenderId = tenderId });
    }

    var existingBookmark = await _context.TenderBookmarks
        .FirstOrDefaultAsync(tb => tb.UserId == userId && tb.TenderId == tenderId);

    if (existingBookmark != null)
    {
        _context.TenderBookmarks.Remove(existingBookmark);
        await _context.SaveChangesAsync();
        _logger.LogInformation("User {UserId} removed tender {TenderId} from bookmarks.", userId, tenderId);
        return false;
    }
    else
    {
        var newBookmark = new TenderBookmark
        {
            UserId = userId,
            TenderId = tenderId,
            BookmarkedAt = DateTime.UtcNow
        };

        _context.TenderBookmarks.Add(newBookmark);
        await _context.SaveChangesAsync();
        _logger.LogInformation("User {UserId} bookmarked tender {TenderId}.", userId, tenderId);
        return true;
    }
}

public async Task<IEnumerable<TenderDTO>> GetBookmarkedTendersAsync(string userId)
{
    _logger.LogInformation("Fetching bookmarked tenders for user {UserId}", userId);

    return await _context.TenderBookmarks
        .Where(tb => tb.UserId == userId)
        .OrderByDescending(tb => tb.BookmarkedAt) 
        .Select(tb => tb.Tender)                 
        .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider) 
        .ToListAsync();
}

        public async Task<IEnumerable<TenderDTO>> GetActiveTenders()
        {
           return await _context.Tenders
                .Where(t => t.Status == TenderStatus.Open)
                  .OrderByDescending(t => t.CreatedAt)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider) 
                .ToListAsync();
        }
        public async Task<IEnumerable<TenderDTO>> GetClosedTenders()
        {
            return await _context.Tenders
                .Where(t => t.Status == TenderStatus.Closed)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider) 
                .ToListAsync();
        }

      
        public async Task<IEnumerable<TenderDTO>> GetCancelledTenders()
        {
            return await _context.Tenders
                .Where(t => t.Status == TenderStatus.Cancelled)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider) 
                .ToListAsync();
        }

        public async Task<IEnumerable<TenderDTO>> GetTendersByCategory(int id)
        {
            var categoryExists = await _context.Categories.AnyAsync(c => c.Id == id);
            if (!categoryExists)
                throw new NotFoundException("Category not found", new { CategoryId = id });

            return await _context.Tenders
                .Where(t => t.CategoryId == id)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();
        }

        public async Task<List<TenderDTO>> GetTendersByUser(string userId)
        {
    
            return await _context.Tenders
                .Where(t => t.CreatedByUserId == userId)
                .OrderByDescending(t => t.CreatedAt)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();
        }


        public override async Task<TenderDTO> Insert(TenderInsertRequest request)
        {
            _logger.LogInformation("Posting tender {Title}", request.Title);

            if (request.Deadline <= DateTime.UtcNow)
                throw new UserException("Deadline must be in the future");

            try  
            {
               

                if(request.LocationId <= 0)
{
                    throw new UserException("Location is required.");
                }

                var category = await _context.Categories
                    .FirstOrDefaultAsync(c => c.Id == request.CategoryId && c.IsActive);
                if (category == null)
                {
                    throw new UserException("The selected category does not exist in our database.");
                }

                var location = await _context.Locations
                    .FirstOrDefaultAsync(l => l.Id == request.LocationId && l.IsActive);
                if (location == null)
                {
                    throw new UserException("The selected location does not exist in our database.");
                }

                var entity = _mapper.Map<Tender>(request);


                entity.LocationId = location.Id;
                entity.Status = TenderStatus.Open;
                entity.PostedAt = DateTime.UtcNow;
                entity.CreatedAt = DateTime.UtcNow;
                entity.CreatedByUserId = _authService.GetCurrentUserId();

                _context.Tenders.Add(entity);

                if (request.Images != null && request.Images.Any())
                {
                    entity.Images = new List<TenderImage>();
                    for (int i = 0; i < request.Images.Count; i++)
                    {
                        var imgReq = request.Images[i];

                        // Dodajemo sliku u bazu i povezujemo je sa tenderom
                        entity.Images.Add(new TenderImage
                        {
                            ImageUrl = imgReq.ImageUrl,
                            ImageHash = imgReq.ImageHash,
                            IsPrimary = i == 0 // Prva slika u nizu je primarna
                        });
                    }
                }

                await _context.SaveChangesAsync();

                return await _context.Tenders
                .Where(t => t.Id == entity.Id)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider)
                .FirstAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error inserting tender: {Message}", ex.Message);
                throw; 
            }
        }

        public async Task<TenderDTO> Cancel(int id)
        {
            var entity = await AddIncludes(_context.Tenders)
                .Include(t => t.Bids) 
                .FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });

            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (entity.CreatedByUserId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();
            }

            var state = CreateState(entity.Status);
            var result = await state.Cancel(id);

            if (entity.Bids != null && entity.Bids.Any())
            {
                foreach (var bid in entity.Bids)
                {
                   
                    bid.Status = ApplicationStatus.Cancelled; 
                     _context.Entry(bid).State = EntityState.Modified;
                }
            }

            await _context.SaveChangesAsync();

            return result;
        }


        public async Task<TenderDTO> Award(int id, int bidId)
        {
            var tender = await AddIncludes(_context.Tenders)
                .FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });

            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (tender.CreatedByUserId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();
            }

            var state = CreateState(tender.Status);

            var resultDto = await state.Award(tender, bidId);

            await _context.SaveChangesAsync();

            return resultDto;
        }


        public async Task<List<string>> AllowedActions(int id)
        {
            var entity = await AddIncludes(_context.Tenders)
                .FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });



            var state = CreateState(entity.Status);

            return await state.AllowedActions(entity);
        }

        public async Task<PagedResult<TenderDTO>> SearchAsync(TenderSearchRequest request)
        {
            var query = _context.Tenders
                .AsQueryable();

            query = query.Where(t => t.Status == TenderStatus.Open);

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = $"%{request.SearchTerm.ToLower()}%";

                query = query.Where(t =>
                    EF.Functions.Like(t.Title.ToLower(), term) ||
                     EF.Functions.Like(t.Description.ToLower(), term)
                );
            }

            var totalCount = await query.CountAsync();

            var results = await query
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            return new PagedResult<TenderDTO>
            {
                Result = results,
                TotalCount = totalCount 
            };
        }

        public async Task<bool> LogUserActivityAsync(string activityType, int? tenderId, string? searchQuery, int? durationSeconds = null)
        {
            var normalizedType = activityType?.Trim();

            return normalizedType switch
            {
                "Search" => await LogSearchAsync(searchQuery),
                "View" => await LogTenderViewAsync(tenderId, durationSeconds),
                _ => throw new UserException("Invalid activity type")
            };
        }

        private async Task<bool> LogTenderViewAsync(int? tenderId, int? durationSeconds)
        {
            if (tenderId == null || durationSeconds == null || durationSeconds < 5)
            {
                return false;
            }

            var tenderExists = await _context.Tenders.AnyAsync(t => t.Id == tenderId.Value);
            if (!tenderExists)
            {
                return false;
            }

            var userId = _authService.GetCurrentUserId();
            var cutoff = DateTime.UtcNow.AddMinutes(-10);
            var alreadyLogged = await _context.UserActivities.AnyAsync(a =>
                a.UserId == userId &&
                a.ActivityType == "View" &&
                a.TenderId == tenderId.Value &&
                a.Timestamp >= cutoff);

            if (alreadyLogged)
            {
                return false;
            }

            await AddUserActivityAsync("View", tenderId.Value, null);
            return true;
        }

        private async Task<bool> LogSearchAsync(string? searchTerm)
        {
            var normalizedSearchTerm = searchTerm?.Trim();
            if (string.IsNullOrWhiteSpace(normalizedSearchTerm))
            {
                return false;
            }

            await AddUserActivityAsync("Search", null, normalizedSearchTerm);
            return true;
        }

        private async Task AddUserActivityAsync(string activityType, int? tenderId, string? searchQuery)
        {
            var userId = _authService.GetCurrentUserId();

            _context.UserActivities.Add(new UserActivity
            {
                UserId = userId,
                ActivityType = activityType,
                TenderId = tenderId,
                SearchQuery = searchQuery,
                Timestamp = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();
        }

       
        public BaseState CreateState(TenderStatus status)
        {
            return status switch
            {
                TenderStatus.Open => _serviceProvider.GetRequiredService<OpenTenderState>(),
                TenderStatus.Closed => _serviceProvider.GetRequiredService<ClosedTenderState>(),
                TenderStatus.Awarded => _serviceProvider.GetRequiredService<AwardedTenderState>(),
                TenderStatus.Cancelled => _serviceProvider.GetRequiredService<CancelledTenderState>(),
                _ => throw new UserException("Invalid tender status")
            };
        }



    }
}
