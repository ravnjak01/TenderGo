using Microsoft.EntityFrameworkCore;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services.Seed
{
    public class RatingsSeeder : IDataSeeder
    {
        public int Order => 9;

        public async Task SeedAsync(TenderGoContext context, IServiceProvider serviceProvider)
        {
            var now = DateTime.UtcNow;

            var awardedTenders = await context.Tenders
                .Include(t => t.WinningBid)
                .Where(t => t.Status == TenderStatus.Awarded)
                .ToListAsync();

            var excludedUser = await context.Users
            .FirstOrDefaultAsync(u => u.Email == "amina@tendergo.com");

            foreach (var tender in awardedTenders)
            {
                var winningBid = tender.WinningBid;

                if (winningBid == null || winningBid.Status != ApplicationStatus.Accepted)
                {
                    continue;
                }

                var isAminaInTender =
                    tender.CreatedByUserId == excludedUser.Id ||
                    winningBid.SubmittedByUserId == excludedUser.Id;

                if (isAminaInTender)
                {
                    continue;
                }

                await AddRatingIfMissingAsync(
                    context,
                    tender.Id,
                    tender.CreatedByUserId,
                    winningBid.SubmittedByUserId,
                    5,
                    "Profesionalna usluga i isporuka u dogovorenom roku.",
                    now.AddDays(-1));

                await AddRatingIfMissingAsync(
                    context,
                    tender.Id,
                    winningBid.SubmittedByUserId,
                    tender.CreatedByUserId,
                    5,
                    "Jasni zahtjevi, korektna komunikacija i brza potvrda dogovora.",
                    now.AddDays(-1));
            }

            await context.SaveChangesAsync();
            await UpdateUserRatingSummariesAsync(context);
        }

        private static async Task AddRatingIfMissingAsync(
            TenderGoContext context,
            int tenderId,
            string ratedByUserId,
            string ratedUserId,
            int score,
            string comment,
            DateTime createdAt)
        {
            if (ratedByUserId == ratedUserId)
            {
                return;
            }

            var exists = await context.Ratings.AnyAsync(r =>
                r.TenderId == tenderId &&
                r.RatedByUserId == ratedByUserId &&
                r.RatedUserId == ratedUserId);

            if (exists)
            {
                return;
            }

            context.Ratings.Add(new Rating
            {
                TenderId = tenderId,
                RatedByUserId = ratedByUserId,
                RatedUserId = ratedUserId,
                Score = score,
                Comment = comment,
                CreatedAt = createdAt
            });
        }

        private static async Task UpdateUserRatingSummariesAsync(TenderGoContext context)
        {
            var allUsers = await context.Users.ToListAsync();
            foreach (var user in allUsers)
            {
                user.AverageRating = 0.0;
                user.RatingCount = 0;
            }

            var ratingGroups = await context.Ratings
                .GroupBy(r => r.RatedUserId)
                .Select(g => new
                {
                    UserId = g.Key,
                    Average = g.Average(r => r.Score),
                    Count = g.Count()
                })
                .ToListAsync();

            foreach (var group in ratingGroups)
            {
                var user = allUsers.FirstOrDefault(u => u.Id == group.UserId);
                if (user != null)
                {
                    user.AverageRating = Math.Round(group.Average, 2);
                    user.RatingCount = group.Count;
                }
            }

            await context.SaveChangesAsync();
        }
    }
}
