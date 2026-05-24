using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace TenderGo.Subscriber
{
    public class Worker : BackgroundService
    {
        private readonly TenderSubscriber _subscriber;
        private readonly ILogger<Worker> _logger;
        private readonly IConfiguration _configuration;

        public Worker(TenderSubscriber subscriber, ILogger<Worker> logger,IConfiguration configuration)
        {
            _logger = logger;
            _subscriber = subscriber;
            _configuration = configuration;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Worker started...");
            var subscriptionId = "notification-service";
            var rabbitConnString = _configuration.GetConnectionString("RabbitMQ") 
                                   ?? "host=localhost;username=guest;password=guest;timeout=30";
            //var safeLogString = SanitizeConnectionString(rabbitConnString);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    _logger.LogInformation("Pokušavam pretplatu na RabbitMQ koristeći: {ConnString}",rabbitConnString);

                    await _subscriber.SubscribeAsync(subscriptionId);
                    _logger.LogInformation(
                        "Uspješno pokrenut RabbitMQ subscriber na mreži! ID pretplate: {Id}", 
                        subscriptionId);

                  
                    await Task.Delay(Timeout.Infinite, stoppingToken);
                    break;
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    var detailedError = ex.InnerException != null ? ex.InnerException.Message : ex.Message;

                    _logger.LogError(
                        ex,
                        "KRIZA: Neuspješno povezivanje na RabbitMQ! Razlog: {Reason}. Pokušavam ponovo za 5 sekundi...",
                        detailedError);
                        
                    await Task.Delay(5000, stoppingToken);
                }
            }
        }
    }
}
