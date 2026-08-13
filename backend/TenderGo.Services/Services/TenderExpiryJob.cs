using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using TenderGo.Api.Database;
using TenderGo.Contracts;
using TenderGo.Models.ENUMs;

namespace TenderGo.Services.Services
{
    public class TenderExpiryJob : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<TenderExpiryJob> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromHours(3);
        private readonly IPubSub _pubSub;

        public TenderExpiryJob(IServiceScopeFactory scopeFactory, ILogger<TenderExpiryJob> logger, IPubSub pubSub)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _pubSub = pubSub;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("TenderExpiryJob started.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
                    await ProcessExpiredTenders(stoppingToken);
                    await Task.Delay(_interval, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška u TenderExpiryJob, nastavlja se za 1 minutu.");

                    try
                    {
                        await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
                    }
                    catch (OperationCanceledException)
                    {
                        break;
                    }
                }
            }

            _logger.LogInformation("TenderExpiryJob stopped.");
        }

        private async Task ProcessExpiredTenders(CancellationToken ct)
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<TenderGoContext>();

            var now = DateTime.UtcNow;

            var expiredTenders = await db.Tenders
                .Where(t => t.Status == TenderStatus.Open && t.Deadline < now)
                .ToListAsync(ct);

            if (!expiredTenders.Any())
            {
                _logger.LogInformation("No expired tenders found at {Time}.", now);
                return;
            }

            foreach (var tender in expiredTenders)
            {
                tender.Status = TenderStatus.Closed;
                tender.UpdatedAt = now;
                tender.UpdatedByUserId = "SYSTEM";
            }

            await db.SaveChangesAsync(ct);

            //foreach (var tender in expiredTenders)
            //{
            //    try
            //    {
            //        await _pubSub.PublishAsync(
            //            new TenderExpiredEvent
            //            {
            //                TenderId = tender.Id,
            //                TenderTitle = tender.Title,
            //                OwnerUserId = tender.CreatedByUserId,
            //                ExpiredAt = DateTime.UtcNow
            //            },
            //            cfg => cfg.WithTopic("tender_expired"));
            //    }
            //    catch (Exception ex)
            //    {
            //        _logger.LogWarning(
            //            ex,
            //            "Tender {TenderId} expired but TenderExpiredEvent was not published",
            //            tender.Id);
            //    }
            //}

            _logger.LogInformation("Auto-closed {Count} tenders.", expiredTenders.Count);
        }
    }
}