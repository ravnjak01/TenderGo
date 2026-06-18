using Microsoft.EntityFrameworkCore;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class AdminDashboardService : IAdminDashboardService
    {
        private const int RecentActivitiesCount = 10;

        private readonly TenderGoContext _context;

        public AdminDashboardService(TenderGoContext context)
        {
            _context = context;
        }

        public async Task<AdminDashboardDTO> GetDashboardAsync()
        {
            var dashboard = new AdminDashboardDTO
            {
                TotalUsers = await _context.Users.AsNoTracking().CountAsync(),
                ActiveTenders = await _context.Tenders
                    .AsNoTracking()
                    .CountAsync(t => t.Status == TenderStatus.Open && !t.IsDeleted),
                TotalCategories = await _context.Categories
                    .AsNoTracking()
                    .CountAsync(c => c.IsActive),
                TotalLocations = await _context.Locations
                    .AsNoTracking()
                    .CountAsync(l => l.IsActive),
                RecentActivities = await GetRecentActivitiesAsync()
            };

            return dashboard;
        }

        private async Task<List<ActivityDTO>> GetRecentActivitiesAsync()
        {
            var registeredUsers = await _context.Users
                .AsNoTracking()
                .OrderByDescending(u => u.CreatedAt)
                .Take(RecentActivitiesCount)
                .Select(u => new ActivityDTO
                {
                    CreatedAt = u.CreatedAt,
                    UserName = u.UserName ?? u.Email ?? string.Empty,
                    ActivityType = ActivityType.UserRegistered,
                    Action = "User registered"
                })
                .ToListAsync();

            var createdTenders = await _context.Tenders
                .AsNoTracking()
                .Where(t => !t.IsDeleted)
                .OrderByDescending(t => t.CreatedAt)
                .Take(RecentActivitiesCount)
                .Select(t => new ActivityDTO
                {
                    CreatedAt = t.CreatedAt,
                    UserName = t.CreatedByUser.UserName ?? t.CreatedByUser.Email ?? string.Empty,
                    ActivityType = ActivityType.TenderCreated,
                    Action = $"Tender created: {t.Title}"
                })
                .ToListAsync();

            var submittedBids = await _context.Bids
                .AsNoTracking()
                .Where(b => !b.IsDeleted)
                .OrderByDescending(b => b.SubmittedAt)
                .Take(RecentActivitiesCount)
                .Select(b => new ActivityDTO
                {
                    CreatedAt = b.SubmittedAt,
                    UserName = b.SubmittedByUser.UserName ?? b.SubmittedByUser.Email ?? string.Empty,
                    ActivityType = ActivityType.BidSubmitted,
                    Action = "Bid submitted"
                })
                .ToListAsync();

            return registeredUsers
                .Concat(createdTenders)
                .Concat(submittedBids)
                .OrderByDescending(a => a.CreatedAt)
                .Take(RecentActivitiesCount)
                .ToList();
        }
    }
}
