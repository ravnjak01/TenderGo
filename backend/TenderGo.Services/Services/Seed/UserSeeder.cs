using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;

namespace TenderGo.Data.Seeders
{
    public class UserSeeder : IDataSeeder
    {
        public int Order => 1;
        public async Task SeedAsync(TenderGoContext context, IServiceProvider serviceProvider)
        {
            var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();

            var testUsers = new List<ApplicationUser>
            {
                new ApplicationUser
                {
                    UserName = "mujo@tendergo.com",
                    Email = "mujo@tendergo.com",
                    EmailConfirmed = true,
                    FirstName = "Mujo",
                    LastName = "Mujačić",
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = "System",
                    IsBanned = false,
                    AverageRating = 4.5,
                    RatingCount = 12,
                    Address = new Address
                    {
                        Country = "Bosna i Hercegovina",
                        City = "Sarajevo",
                        Street = "Ferhadija 15",
                        PostalCode = "71000"
                    }
                },
               
                new ApplicationUser
                {
                    UserName = "amina@tendergo.com",
                    Email = "amina@tendergo.com",
                    EmailConfirmed = true,
                    FirstName = "Amina",
                    LastName = "Hadziabdic",
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = "System",
                    IsBanned = false,
                    AverageRating = 4.7,
                    RatingCount = 9,
                    Address = new Address
                    {
                        Country = "Bosna i Hercegovina",
                        City = "Tuzla",
                        Street = "Korzo 7",
                        PostalCode = "75000"
                    }
                },
                new ApplicationUser
                {
                    UserName = "marko@tendergo.com",
                    Email = "marko@tendergo.com",
                    EmailConfirmed = true,
                    FirstName = "Marko",
                    LastName = "Maric",
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = "System",
                    IsBanned = false,
                    AverageRating = 4.2,
                    RatingCount = 6,
                    Address = new Address
                    {
                        Country = "Bosna i Hercegovina",
                        City = "Banja Luka",
                        Street = "Kralja Petra I 22",
                        PostalCode = "78000"
                    }
                }
            };

            foreach (var user in testUsers)
            {
                var existingUser = await userManager.FindByEmailAsync(user.Email!);

                if (existingUser == null)
                {
                    var result = await userManager.CreateAsync(user, "User123!");

                    if (result.Succeeded)
                    {
                        existingUser = user;
                    }
                    else
                    {
                        var userErrors = string.Join(", ", result.Errors.Select(e => e.Description));
                        throw new Exception($"Failed to seed user {user.Email}: {userErrors}");
                    }
                }

                if (existingUser != null && !await userManager.IsInRoleAsync(existingUser, AppRoles.User))
                {
                    var roleResult = await userManager.AddToRoleAsync(existingUser, AppRoles.User);

                    if (!roleResult.Succeeded)
                    {
                        var roleErrors = string.Join(", ", roleResult.Errors.Select(e => e.Description));
                        throw new Exception($"Failed to assign User role to {existingUser.Email}: {roleErrors}");
                    }
                }
            }
        }
    }
}
