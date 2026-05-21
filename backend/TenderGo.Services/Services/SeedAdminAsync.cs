using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using TenderGo.Models.Entities;

namespace TenderGo.Data 
{
    public static class SeedData
    {
        public static async Task SeedAdminAsync(IServiceProvider serviceProvider)
        {
            var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();
            var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();

            if (!await roleManager.RoleExistsAsync("Admin"))
            {
                await roleManager.CreateAsync(new IdentityRole("Admin"));
            }

            var adminEmail = "admin@tendergo.com";
            var admin = await userManager.FindByEmailAsync(adminEmail);

            if (admin == null)
            {
                admin = new ApplicationUser
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
                    await userManager.AddToRoleAsync(admin, "Admin");
                }
            }
        }
    }
}