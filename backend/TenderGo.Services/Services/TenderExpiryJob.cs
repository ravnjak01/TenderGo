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
using TenderGo.Models.ENUMs;

namespace TenderGo.Services.Services
{
    public class TenderExpiryJob:BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<TenderExpiryJob> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromHours(1);

        public TenderExpiryJob(IServiceScopeFactory scopeFactory, ILogger<TenderExpiryJob> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;

        }
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("TenderExpiryJob started.");

            while (!stoppingToken.IsCancellationRequested)
            {
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
                tender.Status = TenderStatus.Cancelled;
                tender.UpdatedAt = now;
                tender.UpdatedByUserId = "SYSTEM.";
            }

            await db.SaveChangesAsync(ct);
            _logger.LogInformation("Auto-cancelled {Count} tenders.", expiredTenders.Count);
        }
    }
}
