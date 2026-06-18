using Microsoft.EntityFrameworkCore;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;

namespace TenderGo.Data.Seeders
{
    public class LocationSeeder : IDataSeeder
    {
        public int Order => 2;

        public async Task SeedAsync(TenderGoContext context, IServiceProvider serviceProvider)
        {
            var seedLocations = new[]
            {
                new Location { Country = "BiH", Name = "Sarajevo", Region = "Federacija BiH" },
                new Location { Country = "BiH", Name = "Mostar", Region = "Federacija BiH" },
                new Location { Country = "BiH", Name = "Banja Luka", Region = "Republika Srpska" },
                new Location { Country = "BiH", Name = "Tuzla", Region = "Federacija BiH" },
                new Location { Country = "BiH", Name = "Zenica", Region = "Federacija BiH" },
                new Location { Country = "BiH", Name = "Brcko", Region = "Brcko Distrikt" },
                new Location { Country = "BiH", Name = "Bugojno", Region = "Federacija BiH" },

                new Location { Country = "Hrvatska", Name = "Split", Region = "Dalmacija" }
            };

            var locationNames = seedLocations.Select(l => l.Name).ToArray();
            var existingLocationNames = await context.Locations
                .Where(l => locationNames.Contains(l.Name))
                .Select(l => l.Name)
                .ToListAsync();

            foreach (var location in seedLocations)
            {
                if (!existingLocationNames.Contains(location.Name))
                {
                    context.Locations.Add(location);
                }
            }

            await context.SaveChangesAsync();

        }
    }
}