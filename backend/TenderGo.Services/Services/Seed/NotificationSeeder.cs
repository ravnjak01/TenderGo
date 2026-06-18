using Microsoft.EntityFrameworkCore;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;

namespace TenderGo.Data.Seeders
{
    public  class NotificationSeeder: IDataSeeder
    {
        public int Order => 10;

        public async Task SeedAsync(TenderGoContext context, IServiceProvider services)
        {
            await SeedNotificationsAsync(context);
        }
    
        public static async Task SeedNotificationsAsync(TenderGoContext context)
        {
            var users = await context.Users.ToDictionaryAsync(u => u.Email!, u => u);
            await EnsureNotificationsAsync(context, users);
        }

        private static async Task EnsureNotificationsAsync(
            TenderGoContext context,
            Dictionary<string, ApplicationUser> users)
        {
            var notificationSeeds = new[]
            {
                new NotificationSeed("amina@tendergo.com", "Obavijest o  status tendera 'Fotografisanje svadbenog događaja'", "Vaš tender 'Fotografisanje svadbenog događaja' je upravo istekao. Sada možete odabrati pobjednika."),
                new NotificationSeed("mujo@tendergo.com", "Obavijest o  status tendera 'Instalacija video nadzora'", "Vaš tender 'Instalacija video nadzora' je upravo istekao. Sada možete odabrati pobjednika."),
                new NotificationSeed("suljo@tendergo.com", "Obavijest o  status tendera 'Selidba stana'", "Vaš tender 'Selidba stana' je upravo istekao. Sada možete odabrati pobjednika."),
                new NotificationSeed("marko@tendergo.com", "Informacija o tenderu 'Izrada vizuelnog identiteta za restoran'", "Čestitamo! Pobijedili ste na tenderu: Izrada vizuelnog identiteta za restoran."),
                new NotificationSeed("suljo@tendergo.com", "Informacija o tenderu 'Nabavka i montaža kancelarijske opreme'", "Čestitamo! Pobijedili ste na tenderu: Nabavka i montaža kancelarijske opreme."),
                new NotificationSeed("mujo@tendergo.com", "Informacija o tenderu 'Organizacija transporta građevinskog materijala'", "Čestitamo! Pobijedili ste na tenderu: Organizacija transporta građevinskog materijala."),
                new NotificationSeed("amina@tendergo.com", "Informacija o tenderu 'Razvoj sistema za online rezervacije'", "Čestitamo! Pobijedili ste na tenderu: Razvoj sistema za online rezervacije.")
            };

            foreach (var seed in notificationSeeds)
            {
                if (!users.TryGetValue(seed.UserEmail, out var user))
                {
                    continue;
                }

                var exists = await context.Notifications.AnyAsync(n =>
                    n.UserId == user.Id &&
                    n.Title == seed.Title &&
                    n.Message == seed.Message);

                if (!exists)
                {
                    context.Notifications.Add(new Notification
                    {
                        UserId = user.Id,
                        Title = seed.Title,
                        Message = seed.Message,
                        CreatedAt = DateTime.UtcNow.AddHours(-6),
                        IsRead = false
                    });
                }
            }

            await context.SaveChangesAsync();
        }

        private sealed record NotificationSeed(
            string UserEmail,
            string Title,
            string Message);
    }
}
