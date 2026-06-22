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
            var categoryNames = new[]
            {
                "Gradjevinski radovi",
                "IT i razvoj softvera",
                "Dizajn,marketing i fotografija",
                "Transport",
                "Servis i odrzavanje",
                "Namjestaj i oprema",
                "Transport i logistika",
                "Edukacija i konsultacije",
                "Ostalo",
                "Kucne usluge"
            };

            var existingCategories = await context.Categories
                .Where(c => categoryNames.Contains(c.Name))
                .Select(c => c.Name)
                .ToListAsync();

            foreach (var name in categoryNames)
            {
                if (!existingCategories.Contains(name))
                {
                    context.Categories.Add(new Category { Name = name, IsActive = true });
                }
            }

            await context.SaveChangesAsync();
        }
    }
}
