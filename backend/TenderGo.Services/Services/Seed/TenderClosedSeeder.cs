using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services.Seed
{
    public class TenderClosedSeeder:IDataSeeder
    {
        public int Order => 6;

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
                    Title = "Fotografisanje svadbenog događaja",
                    Description = "Potreban profesionalni fotograf za cjelodnevno praćenje svadbe i obradu fotografija.",
                    MaxBudget = 2200.00m,
                    Deadline = now.AddDays(-10),
                    Status = TenderStatus.Closed,
                    PostedAt = now.AddDays(-20),
                    CreatedByUserId = GetValueOrFallback(users, "amina@tendergo.com", "User").Id,
                    LocationId = GetValueOrFallback(locations, "Sarajevo", "Location").Id,
                    CategoryId = GetValueOrFallback(categories, "Dizajn,marketing i fotografija", "Category").Id
                },
                new Tender
                {
                      Title = "Instalacija video nadzora",
                    Description = "Potrebna ugradnja četiri vanjske kamere sa mogućnošću udaljenog pristupa.",
                    MaxBudget = 170.00m,
                    Deadline = now.AddDays(-10),
                    Status = TenderStatus.Closed,
                    PostedAt = now.AddDays(-20),
                    CreatedByUserId = GetValueOrFallback(users, "mujo@tendergo.com", "User").Id,
                    LocationId = GetValueOrFallback(locations, "Mostar", "Location").Id,
                    CategoryId = GetValueOrFallback(categories, "Ostalo", "Category").Id
                },
                new Tender {
                  Title = "Selidba stana",
                    Description = "Potrebna pomoć pri selidbi stvari iz stana na trećem spratu u drugi dio grada.",
                    MaxBudget = 250.00m,
                    Deadline = now.AddDays(-10),
                    Status = TenderStatus.Closed,
                    PostedAt = now.AddDays(-20),
                    CreatedByUserId = GetValueOrFallback(users, "marko@tendergo.com", "User").Id,
                    LocationId = GetValueOrFallback(locations, "Mostar", "Location").Id,
                    CategoryId = GetValueOrFallback(categories, "Transport i logistika", "Category").Id
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
                    existingTender.Description = seedTender.Description;
                    existingTender.MaxBudget = seedTender.MaxBudget;
                    existingTender.Deadline = seedTender.Deadline;
                    existingTender.Status = seedTender.Status;
                    existingTender.PostedAt = seedTender.PostedAt;
                    existingTender.CreatedByUserId = seedTender.CreatedByUserId;
                    existingTender.CategoryId = seedTender.CategoryId;
                    existingTender.LocationId = seedTender.LocationId;
                }
                else
                {
                    context.Tenders.Add(seedTender);
                }
            }

            await context.SaveChangesAsync();

        }
    }
}
