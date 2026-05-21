using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.Threading;
using System.Threading.Tasks;

namespace TenderGo.Subscriber
{
    public class Worker : BackgroundService
    {
        private readonly TenderSubscriber _subscriber;
        private readonly ILogger<Worker> _logger;

        public Worker(TenderSubscriber subscriber,ILogger<Worker>logger)
        {
            _logger = logger;   
            _subscriber = subscriber;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var subscriptionId = "notification-service";

            await _subscriber.SubscribeAsync(subscriptionId);

            _logger.LogInformation("RabbitMQ subscriber started with ID: {Id}", subscriptionId);

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
    }
}