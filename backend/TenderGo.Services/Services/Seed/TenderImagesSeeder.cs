using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services.Seed
{
    public class TenderImagesSeeder:IDataSeeder
    {
        public int Order => 5;

        public async Task SeedAsync(TenderGoContext context, IServiceProvider serviceProvider)
        {
            var env = serviceProvider.GetRequiredService<IWebHostEnvironment>();

            string relativeFolderPath = "uploads/tenders";
            string absoluteFolderPath = Path.Combine(env.WebRootPath, relativeFolderPath);

            var imageMapping= new Dictionary<string,string>
            {
               { "Cijepanje i slaganje ogrjevnog drveta", "drva.jpg" },
            { "Generalno čišćenje apartmana", "apartman.jpg" },
            { "Transport namještaja između gradova", "selidbe.jpg" },
            { "Prevod dokumentacije na engleski jezik", "papiri.png" },
            { "Popravka krovne konstrukcije", "krov.png" },
            { "Košenje i uređenje dvorišta", "trava.png" },
            {"Postavljanje laminata","parket.jpg"}

            };

            var tenderTitles = imageMapping.Keys.ToList();
            var tenders = await context.Tenders
                .Where(t => tenderTitles.Contains(t.Title))
                .ToListAsync();

            var existingImageTenderIds = await context.TenderImages
                .Select(ti => ti.TenderId)
                .Distinct()
                .ToListAsync();

            foreach (var tender in tenders)
            {
                
                    if (existingImageTenderIds.Contains(tender.Id))
                    {
                        continue;
                    }
                    // Uzimamo naziv slike dodijeljen ovom tenderu
                    string imageName = imageMapping[tender.Title];
                    string fullImagePath = Path.Combine(absoluteFolderPath, imageName);

                    // Dodatna sigurnost: Provjeri da li taj fajl stvarno postoji u wwwroot-u
                    if (!File.Exists(fullImagePath))
                    {
                        // Ako slike nema u folderu, preskačemo da se seeder ne sruši
                        continue;
                    }

                    string dbImageUrl = $"/{relativeFolderPath}/{imageName}";

                    // 4. Upisujemo sliku za taj specifičan tender
                    context.TenderImages.Add(new TenderImage
                    {
                        TenderId = tender.Id,
                        ImageUrl = dbImageUrl,
                        IsPrimary = true,
                        ImageHash = Guid.NewGuid().ToString("N")
                    });

            }
            await context.SaveChangesAsync();

        }
    }
}
