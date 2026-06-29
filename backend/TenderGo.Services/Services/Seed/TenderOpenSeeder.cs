using Microsoft.EntityFrameworkCore;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Interfaces;

namespace TenderGo.Data.Seeders
{
    public class TenderOpenSeeder : IDataSeeder
    {
        public int Order => 4;

        public async Task SeedAsync(TenderGoContext context, IServiceProvider serviceProvider)
        {
            var now = DateTime.UtcNow;

            var users = await context.Users.ToDictionaryAsync(u => u.Email!, u => u);
            var categories = await context.Categories.ToDictionaryAsync(c => c.Name, c => c);
            var locations = await context.Locations.ToDictionaryAsync(l => l.Name, l => l);

            T GetValueOrFallback<T>(Dictionary<string, T> dict, string key, string entityName) where T : class
            {
                if (dict.TryGetValue(key, out var val)) return val;
                throw new Exception($"Seeding failed: Required {entityName} '{key}' was not found in the database. Run previous seeders first.");
            }

            var seedTenders = new[]
            {
                new Tender
                {
                    Title = "Cijepanje i slaganje ogrjevnog drveta",
                    Description = "Potrebno iscijepati i složiti oko 10 m³ bukovog drveta.",
                    MaxBudget = 3500.00m,
                    Deadline = now.AddDays(7),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-1),
                    CreatedByUserId = GetValueOrFallback(users, "mujo@tendergo.com", "User").Id,
                    CategoryId = GetValueOrFallback(categories, "Kucne usluge", "Category").Id,
                    LocationId = GetValueOrFallback(locations, "Sarajevo", "Location").Id
                },
                new Tender
                {
                    Title = "Generalno čišćenje apartmana",
                    Description = "Potrebno detaljno čišćenje apartmana od 70 m² nakon odlaska gostiju, uključujući kuhinju i kupatilo.",
                    MaxBudget = 7500.00m,
                    Deadline = now.AddDays(12),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-2),
                    CreatedByUserId = GetValueOrFallback(users, "amina@tendergo.com", "User").Id,
                    CategoryId = GetValueOrFallback(categories, "Kucne usluge", "Category").Id,
                    LocationId = GetValueOrFallback(locations, "Split", "Location").Id
                },
                new Tender
                {
                    Title = "Transport namještaja između gradova",
                    Description = "Potreban kombi prevoz namještaja iz Sarajeva u Mostar. Uključeno utovarivanje i istovarivanje.",
                    MaxBudget = 800.00m,
                    Deadline = now.AddDays(4),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-3),
                    CreatedByUserId = GetValueOrFallback(users, "amina@tendergo.com", "User").Id,
                    CategoryId = GetValueOrFallback(categories, "Transport i logistika", "Category").Id,
                    LocationId = GetValueOrFallback(locations, "Sarajevo", "Location").Id
                },
                new Tender
                {
                    Title = "Prevod dokumentacije na engleski jezik",
                    Description = "Potreban prevod tehničke dokumentacije od približno 50 stranica.",
                    MaxBudget = 300.00m,
                    Deadline = now.AddDays(20),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-5),
                    CreatedByUserId = GetValueOrFallback(users, "marko@tendergo.com", "User").Id,
                    CategoryId = GetValueOrFallback(categories, "Ostalo", "Category").Id,
                    LocationId = GetValueOrFallback(locations, "Banja Luka", "Location").Id
                },
                new Tender
                {
                    Title = "Izrada promotivnog videa",
                    Description = "Potreban kratak promotivni video za lokalni restoran sa montažom i obradom.",
                    MaxBudget = 1500.00m,
                    Deadline = now.AddDays(4),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-10),
                    CreatedByUserId = GetValueOrFallback(users, "mujo@tendergo.com", "User").Id,
                    CategoryId = GetValueOrFallback(categories, "Dizajn,marketing i fotografija", "Category").Id,
                    LocationId = GetValueOrFallback(locations, "Zenica", "Location").Id,
               
                },
                
                new Tender
                {
                    Title = "Popravka krovne konstrukcije",
                    Description = "Potreban majstor za popravku oštećene krovne konstrukcije nakon nevremena.",
                    MaxBudget = 12000.00m,
                    Deadline = now.AddDays(7),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-3),
                    CreatedByUserId = GetValueOrFallback(users, "marko@tendergo.com", "User").Id,
                    LocationId = GetValueOrFallback(locations, "Bugojno", "Location").Id,
                    CategoryId = GetValueOrFallback(categories, "Gradjevinski radovi", "Category").Id,
                },
                 new Tender
                {
                    Title = "Košenje i uređenje dvorišta",
                    Description = "Potrebno pokositi travu i ukloniti korov na parceli od približno 800 m².",
                    MaxBudget = 450.00m,
                    Deadline = now.AddDays(30),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-20),
                    CreatedByUserId = GetValueOrFallback(users, "mujo@tendergo.com", "User").Id,
                    LocationId = GetValueOrFallback(locations, "Mostar", "Location").Id,
                    CategoryId = GetValueOrFallback(categories, "Kucne usluge", "Category").Id,
                },
                 new Tender
                 {
                      Title = "Postavljanje laminata",
                    Description = "Potrebno postavljanje laminata u dnevnom boravku i dvije spavaće sobe.",
                    MaxBudget = 12000.00m,
                    Deadline = now.AddDays(4),
                    Status = TenderStatus.Open,
                    PostedAt = now.AddDays(-10),
                    CreatedByUserId = GetValueOrFallback(users, "amina@tendergo.com", "User").Id,
                    LocationId = GetValueOrFallback(locations, "Zenica", "Location").Id,
                    CategoryId = GetValueOrFallback(categories, "Gradjevinski radovi", "Category").Id,
                 }
            };

            var titles = seedTenders.Select(t => t.Title).ToArray();

            var existingTenders = await context.Tenders
                .IgnoreAutoIncludes()
                .Where(t => titles.Contains(t.Title))
                .ToDictionaryAsync(t => t.Title, t => t);

            foreach (var seedTender in seedTenders)
            {
                if (existingTenders.TryGetValue(seedTender.Title, out var existingTender))
                {
                    // Update postojećeg
                    existingTender.Description = seedTender.Description;
                    existingTender.MaxBudget = seedTender.MaxBudget;
                    existingTender.Deadline = seedTender.Deadline;
                    existingTender.Status = seedTender.Status;
                    existingTender.PostedAt = seedTender.PostedAt;
                    existingTender.CreatedByUserId = seedTender.CreatedByUserId;
                    existingTender.CategoryId = seedTender.CategoryId;
                    existingTender.LocationId = seedTender.LocationId;
                    existingTender.UpdatedAt = seedTender.UpdatedAt;
                    existingTender.UpdatedByUserId = seedTender.UpdatedByUserId;
                }
                else
                {
                    // Add novog
                    context.Tenders.Add(seedTender);
                }
            }

            await context.SaveChangesAsync();
        }
    }
}