using Microsoft.EntityFrameworkCore;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;

namespace TenderGo.Data.Seeders
{
    public class CategorySeeder : IDataSeeder
    {
        public int Order => 3;

        public async Task SeedAsync(TenderGoContext context, IServiceProvider serviceProvider)
        {
            var categories = new[]
{
                    new Category { Name = "Gradjevinski radovi", Description = "Izgradnja, renoviranje i građevinski projekti.", IsActive = true },
                    new Category { Name = "IT i razvoj softvera", Description = "Razvoj aplikacija, web stranica i IT rješenja.", IsActive = true },
                    new Category { Name = "Dizajn,marketing i fotografija", Description = "Grafički dizajn, digitalni marketing i fotografija.", IsActive = true },
                    new Category { Name = "Transport", Description = "Usluge prevoza putnika i robe.", IsActive = true },
                    new Category { Name = "Servis i odrzavanje", Description = "Održavanje i servisiranje opreme i objekata.", IsActive = true },
                    new Category { Name = "Namjestaj i oprema", Description = "Nabavka namještaja, alata i poslovne opreme.", IsActive = true },
                    new Category { Name = "Transport i logistika", Description = "Logističke usluge, skladištenje i distribucija.", IsActive = true },
                    new Category { Name = "Edukacija i konsultacije", Description = "Obuke, seminari i stručne konsultantske usluge.", IsActive = true },
                    new Category { Name = "Ostalo", Description = "Sve usluge koje ne pripadaju ostalim kategorijama.", IsActive = true },
                    new Category { Name = "Kucne usluge", Description = "Čišćenje, popravke i druge usluge za domaćinstva.", IsActive = true }
                };
            var existingCategories = await context.Categories.ToListAsync();

            foreach (var category in categories)
            {
                var existing = existingCategories.FirstOrDefault(c => c.Name == category.Name);

                if (existing == null)
                {
                    context.Categories.Add(category);
                }
                else
                {
                    existing.Description = category.Description;
                    existing.IsActive = category.IsActive;
                }
            }

            await context.SaveChangesAsync();
        }
    }
}
