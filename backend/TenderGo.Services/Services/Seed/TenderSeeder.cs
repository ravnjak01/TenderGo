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

            // Provjera da li u bazi već postoje tenderi
            // 1. KORAK: Povuci testne korisnike (kreatore)
            var mujo = await userManager.FindByEmailAsync("mujo@tendergo.com");
            var suljo = await userManager.FindByEmailAsync("suljo@tendergo.com");
            
            // Fallback ako seederi za usere nisu prošli, uzmi bilo koga
            var defaultUser = mujo ?? suljo ?? await context.Users.FirstOrDefaultAsync();

            if (defaultUser == null)
            {
                throw new Exception("Seeding tenders failed: No users found in the database.");
            }

            // 2. KORAK: Povuci sve lokacije i sve kategorije
            var categories = await context.Categories.ToListAsync();
            var locations = await context.Locations.ToListAsync();

            // Provjera za lokacije (pošto ih više ne kreiramo ovdje)
            if (!locations.Any())
            {
                throw new Exception("Seeding tenders failed: No locations found in the database. Please seed locations first.");
            }

            // Osiguravamo da imamo tačno 6 kategorija (zadržano prema originalnoj logici)
            while (categories.Count < 6)
            {
                int nextIndex = categories.Count + 1;
                var fallbackCategory = new Category { Name = $"Testna Kategorija {nextIndex}" };
                context.Categories.Add(fallbackCategory);
                await context.SaveChangesAsync();
                categories.Add(fallbackCategory);
            }

            if (await context.Tenders.AnyAsync())
            {
                await EnsureExpiredTestTendersAsync(context, mujo ?? defaultUser, suljo ?? defaultUser, categories, locations);
                return;
            }

            // 3. KORAK: Kreiranje 6 tendera
            // Pomoću '% locations.Count' sigurni smo da nećemo izaći van opsega liste lokacija, bez obzira koliko ih ima u bazi
            var testTenders = new List<Tender>
            {
                new Tender
                {
                    Title = "Nabavka i ugradnja PVC stolarije",
                    Description = "Potrebna zamjena 5 prozora i dvoja balkonska vrata na stambenom objektu.",
                    MaxBudget = 3500.00m,
                    Deadline = DateTime.UtcNow.AddDays(1),
                    Status = TenderStatus.Open,
                    PostedAt = DateTime.UtcNow,
                    CreatedByUserId = mujo?.Id ?? defaultUser.Id,
                    CategoryId = categories[0].Id,
                    LocationId = locations[0 % locations.Count].Id
                },
                new Tender
                {
                    Title = "Izrada logotipa i brending za mobilnu aplikaciju",
                    Description = "Traži se grafički dizajner za kreiranje vizuelnog identiteta aplikacije TenderGo.",
                    MaxBudget = 800.00m,
                    Deadline = DateTime.UtcNow.AddDays(2),
                    Status = TenderStatus.Open,
                    PostedAt = DateTime.UtcNow,
                    CreatedByUserId = mujo?.Id ?? defaultUser.Id,
                    CategoryId = categories[1].Id,
                    LocationId = locations[1 % locations.Count].Id
                },
                new Tender
                {
                    Title = "Razvoj E-Commerce Web Portala",
                    Description = "Potrebna izrada web prodavnice u .NET Core i React tehnologijama sa integracijom plaćanja.",
                    MaxBudget = 7500.00m,
                    Deadline = DateTime.UtcNow.AddDays(3),
                    Status = TenderStatus.Open,
                    PostedAt = DateTime.UtcNow,
                    CreatedByUserId = suljo?.Id ?? defaultUser.Id,
                    CategoryId = categories[2].Id,
                    LocationId = locations[2 % locations.Count].Id
                },
                new Tender
                {
                    Title = "Knjigovodstvene usluge za d.o.o. (Godišnji ugovor)",
                    Description = "Traži se agencija za vođenje poslovnih knjiga, obračun plata i pripremu završnih računa.",
                    MaxBudget = 2400.00m,
                    Deadline = DateTime.UtcNow.AddDays(4),
                    Status = TenderStatus.Open,
                    PostedAt = DateTime.UtcNow,
                    CreatedByUserId = suljo?.Id ?? defaultUser.Id,
                    CategoryId = categories[3].Id,
                    LocationId = locations[3 % locations.Count].Id
                },
                new Tender
                {
                    Title = "Servisiranje i održavanje klima uređaja u poslovnom objektu",
                    Description = "Godišnji servis 12 inverter klima uređaja u kancelarijama kompanije.",
                    MaxBudget = 600.00m,
                    Deadline = DateTime.UtcNow.AddDays(5),
                    Status = TenderStatus.Open,
                    PostedAt = DateTime.UtcNow,
                    CreatedByUserId = mujo?.Id ?? defaultUser.Id,
                    CategoryId = categories[4].Id,
                    LocationId = locations[4 % locations.Count].Id
                },
                new Tender
                {
                    Title = "Nabavka kancelarijskog namještaja",
                    Description = "Potrebno opremanje konferencijske sale: 1 veliki stol i 10 ergonomskih stolica.",
                    MaxBudget = 4200.00m,
                    Deadline = DateTime.UtcNow.AddDays(6),
                    Status = TenderStatus.Open,
                    PostedAt = DateTime.UtcNow,
                    CreatedByUserId = suljo?.Id ?? defaultUser.Id,
                    CategoryId = categories[5].Id,
                    LocationId = locations[5 % locations.Count].Id
                }
            };

            context.Tenders.AddRange(testTenders);
            await context.SaveChangesAsync();

            await EnsureExpiredTestTendersAsync(context, mujo ?? defaultUser, suljo ?? defaultUser, categories, locations);
        }

        private static async Task EnsureExpiredTestTendersAsync(
            TenderGoContext context,
            ApplicationUser owner,
            ApplicationUser bidder,
            List<Category> categories,
            List<Location> locations)
        {
            const string closedTenderTitle = "DEV Expired closed tender";
            const string awardedTenderTitle = "DEV Expired awarded tender";

            var existingTitles = await context.Tenders
                .Where(t => t.Title == closedTenderTitle || t.Title == awardedTenderTitle)
                .Select(t => t.Title)
                .ToListAsync();

            var now = DateTime.UtcNow;

            if (!existingTitles.Contains(closedTenderTitle))
            {
                context.Tenders.Add(new Tender
                {
                    Title = closedTenderTitle,
                    Description = "Development seed tender with an expired deadline and Closed status.",
                    MaxBudget = 1500.00m,
                    Deadline = now.AddDays(-3),
                    Status = TenderStatus.Closed,
                    PostedAt = now.AddDays(-10),
                    CreatedByUserId = owner.Id,
                    CategoryId = categories[0].Id,
                    LocationId = locations[0 % locations.Count].Id,
                    UpdatedAt = now,
                    UpdatedByUserId = "SYSTEM"
                });
            }

            if (!existingTitles.Contains(awardedTenderTitle))
            {
                var awardedTender = new Tender
                {
                    Title = awardedTenderTitle,
                    Description = "Development seed tender with an expired deadline, Awarded status, and a winning bid.",
                    MaxBudget = 5000.00m,
                    Deadline = now.AddDays(-7),
                    Status = TenderStatus.Awarded,
                    PostedAt = now.AddDays(-14),
                    CreatedByUserId = owner.Id,
                    CategoryId = categories[1 % categories.Count].Id,
                    LocationId = locations[1 % locations.Count].Id,
                    UpdatedAt = now,
                    UpdatedByUserId = "SYSTEM"
                };

                context.Tenders.Add(awardedTender);
                await context.SaveChangesAsync();

                var winningBid = new Bid
                {
                    TenderId = awardedTender.Id,
                    SubmittedByUserId = bidder.Id,
                    OfferedPrice = 4200.00m,
                    SubmittedAt = now.AddDays(-8),
                    Status = ApplicationStatus.Accepted,
                    Proposal = "Development seed winning bid for notification flow testing.",
                    DeliveryDays = 21,
                    CreatedAt = now.AddDays(-8),
                    CreatedByUserId = bidder.Id
                };

                context.Bids.Add(winningBid);
                await context.SaveChangesAsync();

                awardedTender.WinningBidId = winningBid.Id;
            }

            await context.SaveChangesAsync();

            await EnsureTestTenderNotificationsAsync(context, closedTenderTitle, awardedTenderTitle);
        }

        private static async Task EnsureTestTenderNotificationsAsync(
            TenderGoContext context,
            string closedTenderTitle,
            string awardedTenderTitle)
        {
            var now = DateTime.UtcNow;

            var closedTender = await context.Tenders
                .FirstOrDefaultAsync(t => t.Title == closedTenderTitle);

            if (closedTender != null)
            {
                var closedNotificationTitle = $"Obavijest o  status tendera '{closedTender.Title}'";
                var closedNotificationExists = await context.Notifications.AnyAsync(n =>
                    n.UserId == closedTender.CreatedByUserId &&
                    n.Title == closedNotificationTitle);

                if (!closedNotificationExists)
                {
                    context.Notifications.Add(new Notification
                    {
                        UserId = closedTender.CreatedByUserId,
                        Message = $"Vaš tender '{closedTender.Title}' je upravo istekao. Sada možete odabrati pobjednika.",
                        CreatedAt = now,
                        IsRead = false,
                        Title = closedNotificationTitle
                    });
                }
            }

            var awardedTender = await context.Tenders
                .Include(t => t.WinningBid)
                .FirstOrDefaultAsync(t => t.Title == awardedTenderTitle);

            if (awardedTender?.WinningBid != null)
            {
                var awardedNotificationTitle = $"Informacija o tenderu '{awardedTender.Title}'";
                var awardedNotificationExists = await context.Notifications.AnyAsync(n =>
                    n.UserId == awardedTender.WinningBid.SubmittedByUserId &&
                    n.Title == awardedNotificationTitle);

                if (!awardedNotificationExists)
                {
                    context.Notifications.Add(new Notification
                    {
                        UserId = awardedTender.WinningBid.SubmittedByUserId,
                        Message = $"Čestitamo! Pobijedili ste na tenderu: {awardedTender.Title}.",
                        CreatedAt = now,
                        IsRead = false,
                        Title = awardedNotificationTitle
                    });
                }
            }

            await context.SaveChangesAsync();
        }
    }
}
