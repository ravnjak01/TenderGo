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
            if (await context.Tenders.AnyAsync())
            {
                return; 
            }

            // 1. KORAK: Povuci testne korisnike (kreatore)
            var mujo = await userManager.FindByEmailAsync("mujo@tendergo.com");
            var suljo = await userManager.FindByEmailAsync("suljo@tendergo.com");
            
            // Fallback ako seederi za usere nisu prošli, uzmi bilo koga
            var defaultUser = mujo ?? suljo ?? await context.Users.FirstOrDefaultAsync();

            if (defaultUser == null)
            {
                throw new Exception("Seeding tenders failed: No users found in the database.");
            }

            // 2. KORAK: Povuci sve lokacije i sve kategorije (očekujemo 6 kategorija)
            var categories = await context.Categories.ToListAsync();
            var location = await context.Locations.ToListAsync();

           
            // Osiguravamo da imamo tačno 6 kategorija (makar generisali privremene ako tabela zakaže)
            while (categories.Count < 6)
            {
                int nextIndex = categories.Count + 1;
                var fallbackCategory = new Category { Name = $"Testna Kategorija {nextIndex}" };
                context.Categories.Add(fallbackCategory);
                await context.SaveChangesAsync();
                categories.Add(fallbackCategory); // Dodaj u lokalnu listu
            }

            while (location.Count < 6)
            {
                int nextIndex = location.Count + 1;
                var fallbackLocation = new Location { Name = $"Testna Lokacija {nextIndex}" };
                context.Locations.Add(fallbackLocation);
                await context.SaveChangesAsync();
                location.Add(fallbackLocation); // Dodaj u lokalnu listu
            }

            // 3. KORAK: Kreiranje 6 tendera, svaki sa različitom kategorijom
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
                    CategoryId = categories[0].Id, // 1. Kategorija (npr. Građevinarstvo)
                    LocationId = location[0].Id
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
                    CategoryId = categories[1].Id, // 2. Kategorija (npr. Dizajn / IT)
                    LocationId = location[1].Id
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
                    CategoryId = categories[2].Id, // 3. Kategorija (npr. Softver / Programiranje)
                    LocationId = location[2].Id
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
                    CategoryId = categories[3].Id, // 4. Kategorija (npr. Finansije / Konsalting)
                    LocationId = location[3].Id
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
                    CategoryId = categories[4].Id, // 5. Kategorija (npr. Održavanje / Zanatstvo)
                    LocationId = location[4].Id
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
                    CategoryId = categories[5].Id, // 6. Kategorija (npr. Kancelarijski materijal / Namještaj)
                    LocationId = location[5].Id
                }
            };

            context.Tenders.AddRange(testTenders);
            await context.SaveChangesAsync();
        }
    }
}