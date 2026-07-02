using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services.Seed
{
    public class BidSeeder : IDataSeeder
    {
        public int Order => 8;

        public async Task SeedAsync(TenderGoContext context, IServiceProvider serviceProvider)
        {
            var now = DateTime.UtcNow;

            var users = await context.Users.ToDictionaryAsync(u => u.Email!, u => u);
            var tenders = await context.Tenders.ToDictionaryAsync(t => t.Title, t => t);

            T GetValueOrFallback<T>(Dictionary<string, T> dict, string key, string entityName) where T : class
            {
                if (dict.TryGetValue(key, out var val)) return val;
                throw new Exception($"Bid Seeding failed: Required {entityName} '{key}' was not found in the database.");
            }


            var seedBids = new[]
             {
                new Bid
                {
                    OfferedPrice = 2100.00m,
                    DeliveryDays = 14,
                    Proposal = "Nudim kompletno fotografisanje vjenčanja sa vrhunskom opremom.",
                    Status = ApplicationStatus.Pending,
                    SubmittedAt = now.AddDays(-12),
                    TenderId = GetValueOrFallback(tenders, "Fotografisanje svadbenog događaja", "Tender").Id,
                    SubmittedByUserId = GetValueOrFallback(users, "mujo@tendergo.com", "User").Id
                },

                new Bid
                {
                    OfferedPrice = 160.00m,
                    DeliveryDays = 2,
                    Proposal = "Ugradnja i konfiguracija sistema video nadzora sa garancijom.",
                    Status = ApplicationStatus.Pending,
                    SubmittedAt = now.AddDays(-11),
                    TenderId = GetValueOrFallback(tenders, "Instalacija video nadzora", "Tender").Id,
                    SubmittedByUserId = GetValueOrFallback(users, "amina@tendergo.com", "User").Id
                },
                new Bid
{
    OfferedPrice = 6900.00m,
    DeliveryDays = 3,
    Proposal = "Nudim detaljno čišćenje apartmana sa svom potrebnom opremom i sredstvima.",
    Status = ApplicationStatus.Pending,
    SubmittedAt = now.AddDays(-1),
    TenderId = GetValueOrFallback(tenders, "Generalno čišćenje apartmana", "Tender").Id,
    SubmittedByUserId = GetValueOrFallback(users, "mujo@tendergo.com", "User").Id
},

new Bid
{
    OfferedPrice = 720.00m,
    DeliveryDays = 1,
    Proposal = "Mogu izvršiti transport namještaja kombijem uz utovar i istovar.",
    Status = ApplicationStatus.Pending,
    SubmittedAt = now.AddDays(-2),
    TenderId = GetValueOrFallback(tenders, "Transport namještaja između gradova", "Tender").Id,
    SubmittedByUserId = GetValueOrFallback(users, "marko@tendergo.com", "User").Id
},

new Bid
{
    OfferedPrice = 10500.00m,
    DeliveryDays = 4,
    Proposal = "Nudim postavljanje laminata sa pripremom podloge i završnim lajsnama.",
    Status = ApplicationStatus.Pending,
    SubmittedAt = now.AddDays(-1),
    TenderId = GetValueOrFallback(tenders, "Postavljanje laminata", "Tender").Id,
    SubmittedByUserId = GetValueOrFallback(users, "mujo@tendergo.com", "User").Id
},

                new Bid
                {
                    OfferedPrice = 220.00m,
                    DeliveryDays = 1,
                    Proposal = "Brza selidba sa obezbjeđenim kombi prevozom i radnicima.",
                    Status = ApplicationStatus.Pending,
                    SubmittedAt = now.AddDays(-15),
                    TenderId = GetValueOrFallback(tenders, "Selidba stana", "Tender").Id,
                    SubmittedByUserId = GetValueOrFallback(users, "mujo@tendergo.com", "User").Id
                },

                new Bid
                {
                    OfferedPrice = 2000.00m,
                    DeliveryDays = 13,
                    Proposal = "Garantujemo kvalitetan logo.",
                    Status = ApplicationStatus.Accepted,
                    SubmittedAt = now.AddDays(-16),
                    TenderId = GetValueOrFallback(tenders, "Izrada vizuelnog identiteta za restoran", "Tender").Id,
                    SubmittedByUserId = GetValueOrFallback(users, "marko@tendergo.com", "User").Id
                },

                new Bid
                {
                    OfferedPrice = 4020.00m,
                    DeliveryDays = 5,
                    Proposal = "Brza isporuka kvalitetne opreme.",
                    Status = ApplicationStatus.Accepted,
                    SubmittedAt = now.AddDays(-25),
                    TenderId = GetValueOrFallback(tenders, "Nabavka i montaža kancelarijske opreme", "Tender").Id,
                    SubmittedByUserId = GetValueOrFallback(users, "amina@tendergo.com", "User").Id
                },

                new Bid
                {
                    OfferedPrice = 1700.00m,
                    DeliveryDays = 1,
                    Proposal = "Brz posao garantovan.",
                    Status = ApplicationStatus.Accepted,
                    SubmittedAt = now.AddDays(-15),
                    TenderId = GetValueOrFallback(tenders, "Organizacija transporta građevinskog materijala", "Tender").Id,
                    SubmittedByUserId = GetValueOrFallback(users, "mujo@tendergo.com", "User").Id
                },

                new Bid
                {
                    OfferedPrice = 5500.00m,
                    DeliveryDays = 40,
                    Proposal = "Naš tim osigurava kvalitetnu izradu u navedenom roku.",
                    Status = ApplicationStatus.Accepted,
                    SubmittedAt = now.AddDays(-28),
                    TenderId = GetValueOrFallback(tenders, "Razvoj sistema za online rezervacije", "Tender").Id,
                    SubmittedByUserId = GetValueOrFallback(users, "amina@tendergo.com", "User").Id
                }
            };

            foreach (var seedBid in seedBids)
            {
                var targetTender = await context.Tenders
                    .IgnoreAutoIncludes()
                    .FirstAsync(t => t.Id == seedBid.TenderId);

                if (targetTender.CreatedByUserId == seedBid.SubmittedByUserId)
                {
                    continue;
                }

                var existingBid = await context.Bids
                    .FirstOrDefaultAsync(b => b.TenderId == seedBid.TenderId && b.SubmittedByUserId == seedBid.SubmittedByUserId);

                if (existingBid == null)
                {
                    context.Bids.Add(seedBid);
                }
                else
                {
                    existingBid.OfferedPrice = seedBid.OfferedPrice;
                    existingBid.DeliveryDays = seedBid.DeliveryDays;
                    existingBid.Proposal = seedBid.Proposal;
                    existingBid.Status = seedBid.Status; 
                    existingBid.SubmittedAt = seedBid.SubmittedAt;
                }
            }

            await context.SaveChangesAsync();

            var acceptedBids = await context.Bids
                .Include(b => b.Tender)
                .Include(b => b.SubmittedByUser)
                .Where(b => b.Status == ApplicationStatus.Accepted)
                .ToListAsync();

            foreach (var bid in acceptedBids)
            {
                var tender = bid.Tender;

                tender.Status = TenderStatus.Awarded;
                tender.WinningBidId = bid.Id;

                var otherBids = await context.Bids
                    .Where(b => b.TenderId == tender.Id && b.Id != bid.Id)
                    .ToListAsync();

                foreach (var otherBid in otherBids)
                {
                    otherBid.Status = ApplicationStatus.Rejected;
                }

            }
            await context.SaveChangesAsync();
        }
    }
}