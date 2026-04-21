using EasyNetQ;
using Microsoft.Extensions.Logging;
using System.Threading;
using System.Threading.Tasks;
using TenderGo.Contracts;
using TenderGo.Models.Entities;
using TenderGo.Subscriber.Models;

namespace TenderGo.Subscriber
{
    public class TenderSubscriber
    {
        private readonly IPubSub _pubSub;
        private readonly NotificationDbContext _context;
        private readonly ILogger<TenderSubscriber> _logger;

        public TenderSubscriber(IPubSub pubSub, NotificationDbContext context,ILogger<TenderSubscriber>logger)
        {
            _pubSub = pubSub;
            _context = context;
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
            var notification = new Notification
            {
                UserId = entity.OwnerUserId,
                Message = $"Nova ponuda za tender {entity.TenderId} (iznos: {entity.OfferedPrice})",
                CreatedAt = DateTime.Now,
                IsRead = false
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Notification saved for user {UserId} for tender {TenderId}", entity.OwnerUserId, entity.TenderId);
        }
    }
}