    using EasyNetQ;
    using Microsoft.Extensions.DependencyInjection;
    using Microsoft.Extensions.Logging;
using TenderGo.Api.Database;
using TenderGo.Contracts;
using TenderGo.Models.Entities;

    namespace TenderGo.Subscriber
    {
        public class TenderSubscriber
        {
            private readonly IPubSub _pubSub;
            private readonly IServiceScopeFactory _scopeFactory;
            private readonly ILogger<TenderSubscriber> _logger;
            private bool _subscribed;

            public TenderSubscriber(
                IPubSub pubSub,
                IServiceScopeFactory scopeFactory,
                ILogger<TenderSubscriber> logger)
            {
                _pubSub = pubSub;
                _scopeFactory = scopeFactory;
                _logger = logger;
            }

            public async Task SubscribeAsync(string subscriptionId)
            {
                _logger.LogInformation("Pokušavam subscribe...");
                if (_subscribed)
                {
                    _logger.LogDebug("RabbitMQ subscriptions already active for {SubscriptionId}", subscriptionId);
                    return;
                }
                 _logger.LogInformation("Pokrećem prvu registraciju hendlera za pretplatu {SubscriptionId}...", subscriptionId);
                
                await _pubSub.SubscribeAsync<BidCreatedEvent>(
                    subscriptionId,
                    HandleBidCreated,
                    cfg => cfg.WithTopic("bid_created"));

                await _pubSub.SubscribeAsync<TenderAwardedEvent>(
                    subscriptionId,
                    HandleTenderAwarded,
                    cfg => cfg.WithTopic("tender_awarded"));

                await _pubSub.SubscribeAsync<TenderExpiredEvent>(
                    subscriptionId,
                    HandleTenderExpired,
                    cfg => cfg.WithTopic("tender_expired"));

                _subscribed = true;
                _logger.LogInformation(
                    "Subscribed to bid_created, tender_awarded, tender_expired with ID {SubscriptionId}",
                    subscriptionId);
            }

            private async Task HandleTenderExpired(TenderExpiredEvent entity, CancellationToken cancellationToken)
            {
                _logger.LogInformation("Obrada TenderExpiredEvent za tender {TenderId}", entity.TenderId);

                try
                {
                    using var scope = _scopeFactory.CreateScope();
                    var context = scope.ServiceProvider.GetRequiredService<TenderGoContext>();

                    var notification = new Notification
                    {
                        UserId = entity.OwnerUserId,
                        Message = $"Vaš tender '{entity.TenderTitle}' je upravo istekao. Sada možete odabrati pobjednika.",
                        CreatedAt = DateTime.UtcNow,
                        IsRead = false,
                        Title = $"Obavijest o  status tendera '{entity.TenderTitle}'"
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
                    var context = scope.ServiceProvider.GetRequiredService<TenderGoContext>();

                    var notifications = new List<Notification>();

                    notifications.Add(new Notification
                    {
                        UserId = entity.WinnerUserId,
                        Message = $"Čestitamo! Pobijedili ste na tenderu: {entity.TenderTitle}.",
                        CreatedAt = DateTime.UtcNow,
                        IsRead = false,
                        Title = $"Informacija o tenderu '{entity.TenderTitle}'"
                    });

                    var otherUserIds = entity.OtherUserIds ?? new List<string>();
                    foreach (var userId in otherUserIds.Distinct())
                    {
                        notifications.Add(new Notification
                        {
                            UserId = userId,
                            Message = $"Tender '{entity.TenderTitle}' je završen. Nažalost, vaša ponuda nije odabrana.",
                            CreatedAt = DateTime.UtcNow,
                            IsRead = false,
                            Title = $"Vaša ponuda za tender '{entity.TenderTitle}' nije odabrana"
                        });
                    }

                    context.Notifications.AddRange(notifications);
                    await context.SaveChangesAsync(cancellationToken);

                    _logger.LogInformation(
                        "Spremljeno {Count} notifikacija za završetak tendera {TenderId}",
                        notifications.Count,
                        entity.TenderId);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška prilikom obrade TenderAwardedEvent");
                    throw;
                }
            }

            private async Task HandleBidCreated(BidCreatedEvent entity, CancellationToken cancellationToken)
            {
                _logger.LogInformation(
                    "Primljen BidCreatedEvent za Tender {TenderId} za vlasnika {UserId}",
                    entity.TenderId,
                    entity.OwnerUserId);

                try
                {
                    using var scope = _scopeFactory.CreateScope();
                    var context = scope.ServiceProvider.GetRequiredService<TenderGoContext>();

                    var notification = new Notification
                    {
                        UserId = entity.OwnerUserId,
                        Message = $"Nova ponuda za tender {entity.TenderTitle} (iznos: {entity.OfferedPrice})",
                        CreatedAt = DateTime.UtcNow,
                        IsRead = false,
                        Title = $"Nova ponuda za tender {entity.TenderTitle}"
                    };

                    context.Notifications.Add(notification);
                    await context.SaveChangesAsync(cancellationToken);

                    _logger.LogInformation(
                        "Notifikacija uspješno spremljena za korisnika {UserId} (Tender {TenderId})",
                        entity.OwnerUserId,
                        entity.TenderId);
                }
                catch (Exception ex)
                {
                    _logger.LogError(
                        ex,
                        "Greška prilikom obrade BidCreatedEvent za Tender {TenderId}. Poruka: {Message}",
                        entity.TenderId,
                        ex.Message);
                    throw;
                }
            }
        }
    }
