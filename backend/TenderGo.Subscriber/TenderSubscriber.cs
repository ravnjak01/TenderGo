using EasyNetQ;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Net.NetworkInformation;
using System.Threading;
using System.Threading.Tasks;
using TenderGo.Contracts;
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
                HandleMessage,
                cfg => cfg.WithTopic("bid_created")
            );
        }

        private async Task HandleMessage(BidCreatedEvent entity, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Received BidCreatedEvent for Tender {TenderId} from User {UserId}",
            entity.TenderId, entity.OwnerUserId);

            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();

            var notification = new Notification
            {
                UserId = entity.OwnerUserId,
                Message = $"Nova ponuda za tender {entity.TenderId} (iznos: {entity.OfferedPrice})",
                CreatedAt = DateTime.Now,
                IsRead = false
            };

            context.Notifications.Add(notification);
            await context.SaveChangesAsync();

            _logger.LogInformation("Notification saved for user {UserId} for tender {TenderId}", entity.OwnerUserId, entity.TenderId);
        }
    }
}