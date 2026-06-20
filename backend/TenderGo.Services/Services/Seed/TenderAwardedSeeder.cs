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
    public class TenderAwardedSeeder:IDataSeeder
    {
        public int Order => 7;

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
                Title = "Izrada vizuelnog identiteta za restoran",
                Description = "Potrebna izrada logotipa, menija i promotivnih materijala za novootvoreni restoran.",
                MaxBudget = 2200.00m,
                Deadline = now.AddDays(-15),
                Status = TenderStatus.Awarded,
                PostedAt = now.AddDays(-35),
                CreatedByUserId = GetValueOrFallback(users, "amina@tendergo.com", "User").Id,
                LocationId = GetValueOrFallback(locations, "Sarajevo", "Location").Id,
                CategoryId = GetValueOrFallback(categories, "Dizajn,marketing i fotografija", "Category").Id
            },

            new Tender
            {
                Title = "Nabavka i montaža kancelarijske opreme",
                Description = "Potrebna isporuka i montaža radnih stolova, kancelarijskih stolica i ormara za poslovni prostor.",
                MaxBudget = 4500.00m,
                Deadline = now.AddDays(-20),
                Status = TenderStatus.Awarded,
                PostedAt = now.AddDays(-40),
                CreatedByUserId = GetValueOrFallback(users, "mujo@tendergo.com", "User").Id,
                LocationId = GetValueOrFallback(locations, "Mostar", "Location").Id,
                CategoryId = GetValueOrFallback(categories, "Namjestaj i oprema", "Category").Id
            },

            new Tender
            {
                Title = "Organizacija transporta građevinskog materijala",
                Description = "Potreban prevoz građevinskog materijala između više lokacija u roku od sedam dana.",
                MaxBudget = 1800.00m,
                Deadline = now.AddDays(-12),
                Status = TenderStatus.Awarded,
                PostedAt = now.AddDays(-30),
                CreatedByUserId = GetValueOrFallback(users, "suljo@tendergo.com", "User").Id,
                LocationId = GetValueOrFallback(locations, "Mostar", "Location").Id,
                CategoryId = GetValueOrFallback(categories, "Transport i logistika", "Category").Id
            },

            new Tender
            {
                Title = "Razvoj sistema za online rezervacije",
                Description = "Potrebna web aplikacija za upravljanje rezervacijama smještaja sa administracijskim panelom.",
                MaxBudget = 8500.00m,
                Deadline = now.AddDays(-25),
                Status = TenderStatus.Awarded,
                PostedAt = now.AddDays(-50),
                CreatedByUserId = GetValueOrFallback(users, "marko@tendergo.com", "User").Id,
                LocationId = GetValueOrFallback(locations, "Banja Luka", "Location").Id,
                CategoryId = GetValueOrFallback(categories, "IT i razvoj softvera", "Category").Id
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
