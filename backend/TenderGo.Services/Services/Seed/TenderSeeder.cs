using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;

namespace TenderGo.Data.Seeders
{
    public static class TenderSeeder
    {
        public static async Task SeedTendersAsync(IServiceProvider serviceProvider)
        {
            var context = serviceProvider.GetRequiredService<TenderGoContext>();
            var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();

            var users = await EnsureRequiredUsersAsync(context, userManager);
            var categories = await EnsureCategoriesAsync(context);
            var locations = await EnsureLocationsAsync(context);

            var tenders = await EnsureTendersAsync(context, users, categories, locations);
            await EnsureBidsAsync(context, users, tenders);
            await EnsureRatingsAsync(context, users, tenders);
            await EnsureNotificationsAsync(context, users);
            await UpdateUserRatingSummariesAsync(context);
        }

        private static async Task<Dictionary<string, ApplicationUser>> EnsureRequiredUsersAsync(
            TenderGoContext context,
            UserManager<ApplicationUser> userManager)
        {
            var emails = new[]
            {
                "admin@tendergo.com",
                "mujo@tendergo.com",
                "suljo@tendergo.com",
                "amina@tendergo.com",
                "marko@tendergo.com"
            };

            var users = new Dictionary<string, ApplicationUser>();

            foreach (var email in emails)
            {
                var user = await userManager.FindByEmailAsync(email);
                if (user != null)
                {
                    users[email] = user;
                }
            }

            if (users.Count == 0)
            {
                var fallback = await context.Users.FirstOrDefaultAsync();
                if (fallback == null)
                {
                    throw new Exception("Seeding failed: no users found. Run UserSeeder before TenderSeeder.");
                }

                users["mujo@tendergo.com"] = fallback;
                users["suljo@tendergo.com"] = fallback;
                users["amina@tendergo.com"] = fallback;
                users["marko@tendergo.com"] = fallback;
            }

            foreach (var email in emails)
            {
                if (!users.ContainsKey(email))
                {
                    users[email] = users.Values.First();
                }
            }

            return users;
        }

        private static async Task<Dictionary<string, Category>> EnsureCategoriesAsync(TenderGoContext context)
        {
            var categoryNames = new[]
            {
                "Gradjevinski radovi",
                "IT i razvoj softvera",
                "Dizajn i marketing",
                "Knjigovodstvo i finansije",
                "Servis i odrzavanje",
                "Namjestaj i oprema",
                "Transport i logistika",
                "Edukacija i konsultacije"
            };

            foreach (var name in categoryNames)
            {
                var exists = await context.Categories.AnyAsync(c => c.Name == name);
                if (!exists)
                {
                    context.Categories.Add(new Category { Name = name, IsActive = true });
                }
            }

            await context.SaveChangesAsync();

            return await context.Categories
                .Where(c => categoryNames.Contains(c.Name))
                .GroupBy(c => c.Name)
                .ToDictionaryAsync(g => g.Key, g => g.First());
        }

        private static async Task<Dictionary<string, Location>> EnsureLocationsAsync(TenderGoContext context)
        {
            var seedLocations = new[]
            {
                new Location { Country = "BiH", Name = "Sarajevo", Region = "Federacija BiH" },
                new Location { Country = "BiH", Name = "Mostar", Region = "Federacija BiH" },
                new Location { Country = "BiH", Name = "Banja Luka", Region = "Republika Srpska" },
                new Location { Country = "BiH", Name = "Tuzla", Region = "Federacija BiH" },
                new Location { Country = "BiH", Name = "Zenica", Region = "Federacija BiH" },
                new Location { Country = "BiH", Name = "Brcko", Region = "Brcko Distrikt" }
            };

            foreach (var location in seedLocations)
            {
                var exists = await context.Locations.AnyAsync(l =>
                    l.Country == location.Country &&
                    l.Name == location.Name &&
                    l.Region == location.Region);

                if (!exists)
                {
                    context.Locations.Add(location);
                }
            }

            await context.SaveChangesAsync();

            var names = seedLocations.Select(l => l.Name).ToArray();

            return await context.Locations
                .Where(l => names.Contains(l.Name))
                .GroupBy(l => l.Name)
                .ToDictionaryAsync(g => g.Key, g => g.First());
        }

        private static async Task<Dictionary<string, Tender>> EnsureTendersAsync(
            TenderGoContext context,
            Dictionary<string, ApplicationUser> users,
            Dictionary<string, Category> categories,
            Dictionary<string, Location> locations)
        {
            var now = DateTime.UtcNow;

            var seedTenders = new[]
            {
                new Tender
                {
                    Title = "Nabavka i ugradnja PVC stolarije",
                    Description = "Potrebna zamjena 5 prozora i dvoja balkonska vrata na stambenom objektu.",
                    MaxBudget = 3500.00m,
                    Deadline = now.AddDays(7),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-1),
                    CreatedByUserId = users["mujo@tendergo.com"].Id,
                    CategoryId = categories["Gradjevinski radovi"].Id,
                    LocationId = locations["Sarajevo"].Id
                },
                new Tender
                {
                    Title = "Razvoj E-Commerce web portala",
                    Description = "Potrebna izrada web prodavnice u .NET i React tehnologijama sa integracijom placanja.",
                    MaxBudget = 7500.00m,
                    Deadline = now.AddDays(12),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-2),
                    CreatedByUserId = users["suljo@tendergo.com"].Id,
                    CategoryId = categories["IT i razvoj softvera"].Id,
                    LocationId = locations["Mostar"].Id
                },
                new Tender
                {
                    Title = "Izrada logotipa i brending za mobilnu aplikaciju",
                    Description = "Trazi se graficki dizajner za kreiranje vizuelnog identiteta aplikacije TenderGo.",
                    MaxBudget = 800.00m,
                    Deadline = now.AddDays(4),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-3),
                    CreatedByUserId = users["amina@tendergo.com"].Id,
                    CategoryId = categories["Dizajn i marketing"].Id,
                    LocationId = locations["Tuzla"].Id
                },
                new Tender
                {
                    Title = "Knjigovodstvene usluge za d.o.o.",
                    Description = "Trazi se agencija za vodjenje poslovnih knjiga, obracun plata i zavrsne racune.",
                    MaxBudget = 2400.00m,
                    Deadline = now.AddDays(20),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-5),
                    CreatedByUserId = users["marko@tendergo.com"].Id,
                    CategoryId = categories["Knjigovodstvo i finansije"].Id,
                    LocationId = locations["Banja Luka"].Id
                },
                new Tender
                {
                    Title = "DEV Expired closed tender",
                    Description = "Development seed tender with an expired deadline and Closed status.",
                    MaxBudget = 1500.00m,
                    Deadline = now.AddDays(-3),
                    Status = TenderStatus.Closed,
                    PostedAt = now.AddDays(-10),
                    CreatedByUserId = users["mujo@tendergo.com"].Id,
                    CategoryId = categories["Servis i odrzavanje"].Id,
                    LocationId = locations["Zenica"].Id,
                    UpdatedAt = now,
                    UpdatedByUserId = "SYSTEM"
                },
                new Tender
                {
                    Title = "DEV Expired awarded tender",
                    Description = "Development seed tender with an expired deadline, Awarded status, and a winning bid.",
                    MaxBudget = 5000.00m,
                    Deadline = now.AddDays(-7),
                    Status = TenderStatus.Awarded,
                    PostedAt = now.AddDays(-14),
                    CreatedByUserId = users["suljo@tendergo.com"].Id,
                    CategoryId = categories["Namjestaj i oprema"].Id,
                    LocationId = locations["Brcko"].Id,
                    UpdatedAt = now,
                    UpdatedByUserId = "SYSTEM"
                }
            };

            foreach (var seedTender in seedTenders)
            {
                var exists = await context.Tenders.AnyAsync(t => t.Title == seedTender.Title);
                if (!exists)
                {
                    context.Tenders.Add(seedTender);
                }
            }

            await context.SaveChangesAsync();

            var titles = seedTenders.Select(t => t.Title).ToArray();

            return await context.Tenders
                .Where(t => titles.Contains(t.Title))
                .GroupBy(t => t.Title)
                .ToDictionaryAsync(g => g.Key, g => g.First());
        }

        private static async Task EnsureBidsAsync(
            TenderGoContext context,
            Dictionary<string, ApplicationUser> users,
            Dictionary<string, Tender> tenders)
        {
            var now = DateTime.UtcNow;
            var bidSeeds = new[]
            {
                new BidSeed("Nabavka i ugradnja PVC stolarije", "suljo@tendergo.com", 3200.00m, 14, ApplicationStatus.Pending, "Mogu zavrsiti ugradnju u dvije faze sa garancijom od 24 mjeseca."),
                new BidSeed("Nabavka i ugradnja PVC stolarije", "amina@tendergo.com", 3450.00m, 10, ApplicationStatus.Pending, "U ponudu je ukljucen izlazak na teren, demontaza i odvoz stare stolarije."),
                new BidSeed("Razvoj E-Commerce web portala", "mujo@tendergo.com", 6900.00m, 45, ApplicationStatus.Pending, "Predlazem MVP u prvoj fazi, zatim integracije placanja i dostave."),
                new BidSeed("Razvoj E-Commerce web portala", "marko@tendergo.com", 7300.00m, 35, ApplicationStatus.Rejected, "Kompletan frontend, backend i deployment na cloud okruzenje."),
                new BidSeed("Izrada logotipa i brending za mobilnu aplikaciju", "marko@tendergo.com", 750.00m, 7, ApplicationStatus.Pending, "Tri pravca dizajna, knjiga standarda i eksport za mobilne storeove."),
                new BidSeed("Knjigovodstvene usluge za d.o.o.", "amina@tendergo.com", 2200.00m, 365, ApplicationStatus.Pending, "Mjesecni paket sa PDV prijavama, platama i savjetovanjem."),
                new BidSeed("DEV Expired closed tender", "suljo@tendergo.com", 1300.00m, 5, ApplicationStatus.Pending, "Expired closed tender sample bid ready for award flow testing."),
                new BidSeed("DEV Expired awarded tender", "amina@tendergo.com", 4200.00m, 21, ApplicationStatus.Accepted, "Development seed winning bid for notification flow testing."),
                new BidSeed("DEV Expired awarded tender", "marko@tendergo.com", 4550.00m, 18, ApplicationStatus.Rejected, "Alternative rejected bid for awarded tender.")
            };

            foreach (var seed in bidSeeds)
            {
                var tender = tenders[seed.TenderTitle];
                var user = users[seed.UserEmail];

                var existingBid = await context.Bids.FirstOrDefaultAsync(b =>
                    b.TenderId == tender.Id &&
                    b.SubmittedByUserId == user.Id);

                if (existingBid == null)
                {
                    context.Bids.Add(new Bid
                    {
                        TenderId = tender.Id,
                        SubmittedByUserId = user.Id,
                        OfferedPrice = seed.OfferedPrice,
                        DeliveryDays = seed.DeliveryDays,
                        Status = seed.Status,
                        Proposal = seed.Proposal,
                        SubmittedAt = now.AddDays(-2),
                        CreatedAt = now.AddDays(-2),
                        CreatedByUserId = user.Id
                    });
                }
                else
                {
                    existingBid.OfferedPrice = seed.OfferedPrice;
                    existingBid.DeliveryDays = seed.DeliveryDays;
                    existingBid.Status = seed.Status;
                    existingBid.Proposal = seed.Proposal;
                    existingBid.UpdatedAt = now;
                    existingBid.UpdatedByUserId = "SYSTEM";
                }
            }

            await context.SaveChangesAsync();

            var awardedTender = tenders["DEV Expired awarded tender"];
            var winningBid = await context.Bids.FirstOrDefaultAsync(b =>
                b.TenderId == awardedTender.Id &&
                b.SubmittedByUserId == users["amina@tendergo.com"].Id &&
                b.Status == ApplicationStatus.Accepted);

            if (winningBid != null && awardedTender.WinningBidId != winningBid.Id)
            {
                awardedTender.WinningBidId = winningBid.Id;
                await context.SaveChangesAsync();
            }
        }

        private static async Task EnsureRatingsAsync(
            TenderGoContext context,
            Dictionary<string, ApplicationUser> users,
            Dictionary<string, Tender> tenders)
        {
            var ratingSeeds = new[]
            {
                new RatingSeed("DEV Expired awarded tender", "suljo@tendergo.com", "amina@tendergo.com", 5, "Odlicna komunikacija i isporuka prije roka."),
                new RatingSeed("DEV Expired awarded tender", "amina@tendergo.com", "suljo@tendergo.com", 5, "Jasni zahtjevi i brza potvrda dogovora.")
            };

            if (tenders.TryGetValue("DEV Expired closed tender", out var closedTender))
            {
                var invalidClosedTenderRatings = await context.Ratings
                    .Where(r => r.TenderId == closedTender.Id)
                    .ToListAsync();

                context.Ratings.RemoveRange(invalidClosedTenderRatings);
            }

            foreach (var seed in ratingSeeds)
            {
                var tender = tenders[seed.TenderTitle];
                var ratedBy = users[seed.RatedByEmail];
                var ratedUser = users[seed.RatedUserEmail];

                var exists = await context.Ratings.AnyAsync(r =>
                    r.TenderId == tender.Id &&
                    r.RatedByUserId == ratedBy.Id &&
                    r.RatedUserId == ratedUser.Id);

                if (!exists)
                {
                    context.Ratings.Add(new Rating
                    {
                        TenderId = tender.Id,
                        RatedByUserId = ratedBy.Id,
                        RatedUserId = ratedUser.Id,
                        Score = seed.Score,
                        Comment = seed.Comment,
                        CreatedAt = DateTime.UtcNow.AddDays(-1)
                    });
                }
            }

            await context.SaveChangesAsync();
        }

        private static async Task EnsureNotificationsAsync(
            TenderGoContext context,
            Dictionary<string, ApplicationUser> users)
        {
            var notificationSeeds = new[]
            {
                new NotificationSeed("mujo@tendergo.com", "Nova ponuda za PVC stolariju", "Suljo je poslao ponudu za tender 'Nabavka i ugradnja PVC stolarije'."),
                new NotificationSeed("suljo@tendergo.com", "Tender je dodijeljen", "Tender 'DEV Expired awarded tender' je dodijeljen pobjedniku."),
                new NotificationSeed("amina@tendergo.com", "Cestitamo, ponuda je prihvacena", "Vasa ponuda za 'DEV Expired awarded tender' je prihvacena."),
                new NotificationSeed("mujo@tendergo.com", "Tender je istekao", "Tender 'DEV Expired closed tender' je istekao i spreman je za odabir pobjednika.")
            };

            foreach (var seed in notificationSeeds)
            {
                var user = users[seed.UserEmail];
                var exists = await context.Notifications.AnyAsync(n =>
                    n.UserId == user.Id &&
                    n.Title == seed.Title);

                if (!exists)
                {
                    context.Notifications.Add(new Notification
                    {
                        UserId = user.Id,
                        Title = seed.Title,
                        Message = seed.Message,
                        CreatedAt = DateTime.UtcNow.AddHours(-6),
                        IsRead = false
                    });
                }
            }

            await context.SaveChangesAsync();
        }

        private static async Task UpdateUserRatingSummariesAsync(TenderGoContext context)
        {
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
                var user = await context.Users.FindAsync(group.UserId);
                if (user != null)
                {
                    user.AverageRating = Math.Round(group.Average, 2);
                    user.RatingCount = group.Count;
                }
            }

            await context.SaveChangesAsync();
        }

        private sealed record BidSeed(
            string TenderTitle,
            string UserEmail,
            decimal OfferedPrice,
            int DeliveryDays,
            ApplicationStatus Status,
            string Proposal);

        private sealed record RatingSeed(
            string TenderTitle,
            string RatedByEmail,
            string RatedUserEmail,
            int Score,
            string Comment);

        private sealed record NotificationSeed(
            string UserEmail,
            string Title,
            string Message);
    }
}
