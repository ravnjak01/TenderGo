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
using QuestPDF.Helpers;
using System;
using System.Collections;
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
    public class TenderService : BaseService<TenderDTO, Tender, TenderSearchRequest,TenderInsertRequest, TenderUpdateRequest>, ITenderService
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

        protected override IQueryable<Tender> ApplySorting(IQueryable<Tender> query)
        {
            return query.OrderByDescending(t => t.CreatedAt); 
        }
      
        public override async Task<TenderDTO> Update(int id, TenderUpdateRequest request)
        {
            var entity = await _context.Tenders
                .Include(t => t.Images)
                .FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException("Tender",id);

            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (entity.CreatedByUserId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();
            }

            if (request.Deadline <= DateTime.UtcNow)
                throw new UserException("Deadline must be in the future");

            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == request.CategoryId && c.IsActive)
               ?? throw new NotFoundException("Category", request.LocationId);

            var location = await _context.Locations
                .FirstOrDefaultAsync(l => l.Id == request.LocationId && l.IsActive)
                ?? throw new NotFoundException("Location", request.LocationId);

            _mapper.Map(request, entity);

            entity.CategoryId = category.Id;
            entity.LocationId = location.Id;

            if (request.Images != null)
            {
                _context.TenderImages.RemoveRange(entity.Images);
                entity.Images.Clear();

                for (int i = 0; i < request.Images.Count; i++)
                {
                    var imgReq = request.Images[i];
                    entity.Images.Add(new TenderImage
                    {
                        ImageUrl = imgReq.ImageUrl,
                        ImageHash = imgReq.ImageHash,
                        IsPrimary = i == 0 
                    });
                }
            }

            _context.Entry(entity).State = EntityState.Modified;
            await _context.SaveChangesAsync();

            return await _context.Tenders
                .Where(t => t.Id == entity.Id)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider)
                .FirstAsync();
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
        throw new NotFoundException("Tender",tenderId);
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

        public async Task<PagedResult<TenderDTO>> GetBookmarkedTendersAsync(string userId, PagedSearchRequest search)
        {
            _logger.LogInformation("Fetching bookmarked tenders for user {UserId}", userId);

            var query = _context.TenderBookmarks
                .AsNoTracking()
                .Where(tb => tb.UserId == userId && !tb.Tender.IsDeleted);

            var totalCount = await query.CountAsync();

            int page = search.Page > 0 ? search.Page : 1;
            int pageSize = search.PageSize > 0 ? search.PageSize : 10;

            var results = await query
                .OrderByDescending(tb => tb.BookmarkedAt)
                .Select(tb => tb.Tender)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            return new PagedResult<TenderDTO>
            {
                Result = results,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }
       

        public async Task<PagedResult<TenderDTO>> GetMyTenders(string userId, PagedSearchRequest search)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == userId);
            if (!userExists)
                throw new NotFoundException("User",userId);

            var query = _context.Tenders
                .AsNoTracking()
                .Where(t => t.CreatedByUserId == userId && !t.IsDeleted);

            var totalCount = await query.CountAsync();

            int page = search.Page > 0 ? search.Page : 1;
            int pageSize = search.PageSize > 0 ? search.PageSize : 10;

            var results = await query
                .OrderByDescending(t => t.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            return new PagedResult<TenderDTO>
            {
                Result = results,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

     

        public override async Task<TenderDTO> Insert(TenderInsertRequest request)
        {
            _logger.LogInformation("Posting tender {Title}", request.Title);

            if (request.Deadline <= DateTime.UtcNow)
                throw new UserException("Deadline must be in the future");

                var category = await _context.Categories
                    .FirstOrDefaultAsync(c => c.Id == request.CategoryId && c.IsActive);
            
                var location = await _context.Locations
                    .FirstOrDefaultAsync(l => l.Id == request.LocationId && l.IsActive);
              

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

                        entity.Images.Add(new TenderImage
                        {
                            ImageUrl = imgReq.ImageUrl,
                            ImageHash = imgReq.ImageHash,
                            IsPrimary = i == 0 
                        });
                    }
                }

                await _context.SaveChangesAsync();

                return await _context.Tenders
                .Where(t => t.Id == entity.Id)
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider)
                .FirstAsync();
        }

        public async Task<TenderDTO> Cancel(int id,TenderCancelRequest request)
        {
            var entity = await AddIncludes(_context.Tenders)
                .Include(t => t.Bids) 
                .FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException("Tender", id);

            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (entity.CreatedByUserId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();
            }

            var state = CreateState(entity.Status);
            var result = await state.Cancel(id,request);

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
                ?? throw new NotFoundException("Tender", id);

            var currentUserId = _authService.GetCurrentUserId();

            if (tender.CreatedByUserId != currentUserId )
            {
                throw new ForbiddenException();
            }

            var state = CreateState(tender.Status);

            return await state.Award(tender, bidId);
        }


        public async Task<List<string>> AllowedActions(int id)
        {
            var entity = await AddIncludes(_context.Tenders)
                .FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException("Tender", id);



            var state = CreateState(entity.Status);

            return await state.AllowedActions(entity);
        }

        protected override IQueryable<Tender> ApplyFilter(IQueryable<Tender> query, TenderSearchRequest request)
        {
            query = query.Where(t => !t.IsDeleted);

            var isAdmin = _authService.IsInRole(AppRoles.Admin);
            if (!isAdmin)
            {
                query = query.Where(t => t.Status == TenderStatus.Open);
            }

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var search = request.SearchTerm.Trim().ToLower();
                query = query.Where(t =>
                    t.Title.ToLower().Contains(search) ||
                    (t.Description != null && t.Description.ToLower().Contains(search))
                );
            }

            if (request.CategoryIds != null && request.CategoryIds.Any())
            {
                query = query.Where(t => request.CategoryIds.Contains(t.CategoryId));
            }
            else if (request.CategoryId.HasValue)
            {
                query = query.Where(t => t.CategoryId == request.CategoryId.Value);
            }

            if (request.LocationId.HasValue)
                query = query.Where(t => t.LocationId == request.LocationId.Value);

            if (!string.IsNullOrWhiteSpace(request.Country))
                query = query.Where(t => t.Location.Country.ToLower() == request.Country.ToLower());

            if (!string.IsNullOrWhiteSpace(request.Region))
                query = query.Where(t => t.Location.Region != null && t.Location.Region.ToLower() == request.Region.ToLower());


            return query;
        }
        public async Task<PagedResult<AdminTenderDTO>> GetAdminTendersAsync(TenderSearchRequest request)
        {
            var query = _context.Tenders.AsQueryable();

            query = ApplyFilter(query, request);

            var totalCount = await query.CountAsync();

            var page = request.Page > 0 ? request.Page : 1;
            var pageSize = request.PageSize > 0 ? request.PageSize : 10;

            var list = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<AdminTenderDTO>
            {
                Result = _mapper.Map<List<AdminTenderDTO>>(list),
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
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
                a.ActivityType == ActivityRecommendType.TenderViewed &&
                a.TenderId == tenderId.Value &&
                a.Timestamp >= cutoff);

            if (alreadyLogged)
            {
                return false;
            }

            await AddUserActivityAsync(ActivityRecommendType.TenderViewed, tenderId.Value, null);
            return true;
        }

        private async Task<bool> LogSearchAsync(string? searchTerm)
        {
            var normalizedSearchTerm = searchTerm?.Trim();
            if (string.IsNullOrWhiteSpace(normalizedSearchTerm))
            {
                return false;
            }

            await AddUserActivityAsync(ActivityRecommendType.TenderSearch, null, normalizedSearchTerm);
            return true;
        }

        private async Task AddUserActivityAsync(ActivityRecommendType activityType, int? tenderId, string? searchQuery)
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
                _ => throw new ArgumentOutOfRangeException("Invalid tender status")
            };
        }



    }
}
