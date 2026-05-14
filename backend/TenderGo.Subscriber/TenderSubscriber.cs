using EasyNetQ;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Net.NetworkInformation;
using System.Threading;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Subscriber.Models;
using static System.Formats.Asn1.AsnWriter;

namespace TenderGo.Subscriber
{
    public class TenderSubscriber
    {
        private readonly IPubSub _pubSub;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<TenderSubscriber> _logger;

        public TenderSubscriber(IPubSub pubSub, IServiceScopeFactory scopeFactory, ILogger<TenderSubscriber>logger)
        {
            _pubSub = pubSub;
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        public async Task SubscribeAsync(string subscriptionId)
        {
            await _pubSub.SubscribeAsync<BidCreatedEvent>(
                subscriptionId,
                HandleBidCreated,
                cfg => cfg.WithTopic("bid_created")
            );

            await _pubSub.SubscribeAsync<TenderAwardedEvent>(
            subscriptionId,
            HandleTenderAwarded,
            cfg => cfg.WithTopic("tender_awarded")
            );

            await _pubSub.SubscribeAsync<TenderExpiredEvent>(
            subscriptionId,
            HandleTenderExpired,
            cfg => cfg.WithTopic("tender_expired")
        );
        }

        private async Task HandleTenderExpired(TenderExpiredEvent entity, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Obrada TenderExpiredEvent za tender {TenderId}", entity.TenderId);

            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();

                var notification = new Notification
                {
                    UserId = entity.OwnerUserId,
                    Message = $"Vaš tender '{entity.TenderTitle}' je upravo istekao. Sada možete odabrati pobjednika.",
                    CreatedAt = DateTime.UtcNow,
                    IsRead = false
                };

                context.Notifications.Add(notification);
                await context.SaveChangesAsync(cancellationToken);

                _logger.LogInformation("Notifikacija o isteku poslana vlasniku {UserId}", entity.OwnerUserId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Greška prilikom obrade TenderExpiredEvent");
                throw;
            }
        }

        private async Task HandleTenderAwarded(TenderAwardedEvent entity, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Obrada TenderAwardedEvent za tender {TenderId}", entity.TenderId);

            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();

                var notifications = new List<Notification>();

                // 1. Notifikacija za pobjednika
                notifications.Add(new Notification
                {
                    UserId = entity.WinnerUserId,
                    Message = $"Čestitamo! Pobijedili ste na tenderu: {entity.TenderTitle}.",
                    CreatedAt = DateTime.UtcNow,
                    IsRead = false
                });

                // 2. Notifikacije za ostale (koji su izgubili)
                foreach (var userId in entity.OtherUserIds.Distinct())
                {
                    notifications.Add(new Notification
                    {
                        UserId = userId,
                        Message = $"Tender '{entity.TenderTitle}' je završen. Nažalost, vaša ponuda nije odabrana.",
                        CreatedAt = DateTime.UtcNow,
                        IsRead = false
                    });
                }

                context.Notifications.AddRange(notifications);
                await context.SaveChangesAsync(cancellationToken);

                _logger.LogInformation("Spremljeno {Count} notifikacija za završetak tendera {TenderId}",
                    notifications.Count, entity.TenderId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Greška prilikom obrade TenderAwardedEvent");
                throw;
            }
        }


        private async Task HandleBidCreated(BidCreatedEvent entity, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Primljen BidCreatedEvent za Tender {TenderId} od korisnika {UserId}",
                entity.TenderId, entity.OwnerUserId);

            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();

                var notification = new Notification
                {
                    UserId = entity.OwnerUserId,
                    Message = $"Nova ponuda za tender {entity.TenderId} (iznos: {entity.OfferedPrice})",
                    CreatedAt = DateTime.UtcNow,
                    IsRead = false
                };

                context.Notifications.Add(notification);
                await context.SaveChangesAsync(cancellationToken);

                _logger.LogInformation("Notifikacija uspješno spremljena za korisnika {UserId} (Tender {TenderId})",
                    entity.OwnerUserId, entity.TenderId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Greška prilikom obrade BidCreatedEvent za Tender {TenderId}. Poruka: {Message}",
                    entity.TenderId, ex.Message);

                throw;
            }
        }
    }
}