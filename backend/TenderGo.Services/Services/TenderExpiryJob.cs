using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.ENUMs;

namespace TenderGo.Services.Services
{
    public class TenderExpiryJob:BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<TenderExpiryJob> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromHours(3);
        private readonly IPubSub _pubSub;

        public TenderExpiryJob(IServiceScopeFactory scopeFactory, ILogger<TenderExpiryJob> logger,IPubSub pubSub)
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
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
                await ProcessExpiredTenders(stoppingToken);
                await Task.Delay(_interval, stoppingToken);
            }
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
                tender.UpdatedByUserId = "SYSTEM.";

                //await _pubSub.PublishAsync(new TenderExpiredEvent
                //{
                //    TenderId = tender.Id,
                //    TenderTitle = tender.Title,
                //    OwnerUserId = tender.CreatedByUserId,
                //    ExpiredAt = DateTime.UtcNow
                //}, cfg => cfg.WithTopic("tender_expired"));
            }

            await db.SaveChangesAsync(ct);
            _logger.LogInformation("Auto-cancelled {Count} tenders.", expiredTenders.Count);
        }
    }
}
