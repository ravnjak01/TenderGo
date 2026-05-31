using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using TenderGo.Models.Entities;

namespace TenderGo.Services.Seed;
public static class IdentitySeeder
{
    public static async Task SeedRolesAndAdminAsync(IServiceProvider serviceProvider)
    {
        var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();

        // 1. Seed Rola
        if (!await roleManager.RoleExistsAsync(AppRoles.Admin))
        {
            await roleManager.CreateAsync(new IdentityRole(AppRoles.Admin));
        }
        if (!await roleManager.RoleExistsAsync(AppRoles.User))
        {
            await roleManager.CreateAsync(new IdentityRole(AppRoles.User));
        }

        // 2. Seed Admin Korisnika
        var adminEmail = "admin@tendergo.com";
        var adminUser = await userManager.FindByEmailAsync(adminEmail);

        if (adminUser == null)
        {
            var admin = new ApplicationUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                EmailConfirmed = true,
                FirstName = "Sistem",
                LastName = "Administrator",
                CreatedAt = DateTime.UtcNow,
                Address = new Address
                {
                    Country = "Bosna i Hercegovina",
                    City = "Sarajevo",
                    Street = "Admin Street",
                    PostalCode = "71000"
                }
            };

            var result = await userManager.CreateAsync(admin, "Admin123!");

            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(admin, AppRoles.Admin);
            }
            else
            {
                // Ako ne uspije, ispiši greške u konzolu/logger radi lakšeg debugiranja
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                throw new Exception($"Seed Admin failed: {errors}");
            }
        }
    }
}