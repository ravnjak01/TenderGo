using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using TenderGo.Models.Entities;

namespace TenderGo.Data // Dodaj namespace tvog projekta
{
    public static class SeedData
    {
        public static async Task SeedAdminAsync(IServiceProvider serviceProvider)
        {
            var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();

            var adminEmail = "admin@tendergo.com";
            var admin = await userManager.FindByEmailAsync(adminEmail);

            if (admin == null)
            {
                admin = new ApplicationUser
                {
                    UserName = adminEmail,
                    Email = adminEmail,
                    EmailConfirmed = true // Preporuka: potvrdi email odmah
                };

                var result = await userManager.CreateAsync(admin, "Admin123!");

                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(admin, "Admin"); // Proveri da li je AppRoles.Admin string
                }
            }
        }
    }
}