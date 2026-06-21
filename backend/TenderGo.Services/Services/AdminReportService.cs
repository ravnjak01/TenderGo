using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class AdminReportService : IAdminReportService
    {
        private readonly TenderGoContext _context;

        public AdminReportService(TenderGoContext context)
        {
            _context = context;
        }

        public async Task<byte[]> GenerateReportAsync(AdminReportRequest request)
        {
            var query = _context.Tenders
                .Include(t => t.Location)
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .AsNoTracking()
                .Where(t => !t.IsDeleted)
                .AsQueryable();

            if (request.From.HasValue)
            {
                query = query.Where(t => t.CreatedAt >= request.From.Value);
            }

            if (request.To.HasValue)
            {
                var to = request.To.Value;
                query = to.TimeOfDay == TimeSpan.Zero
                    ? query.Where(t => t.CreatedAt < to.Date.AddDays(1))
                    : query.Where(t => t.CreatedAt <= to);
            }

            var tenders = await query
                .OrderBy(t => t.Location.Country)
                .ThenBy(t => t.Location.Region)
                .ThenBy(t => t.Location.Name)
                .ThenByDescending(t => t.CreatedAt)
                .ToListAsync();

            var document = new AdminTenderReportDocument(tenders, request.From, request.To);

            return document.GeneratePdf();
        }

        public async Task<AdminReportOverviewDTO> GetAdminReportOverview()
        {
            var totalTenders = await _context.Tenders.CountAsync();
            var completedTenders = await _context.Tenders.CountAsync(t => t.Status == TenderStatus.Awarded);

            return new AdminReportOverviewDTO
            {
                TotalTenderValue = await _context.Tenders.SumAsync(t => t.MaxBudget),
                TenderRealizationPercentage = totalTenders == 0 ? 0 : (double)completedTenders / totalTenders * 100,
                CancelledTenderCount = await _context.Tenders.CountAsync(t => t.Status == TenderStatus.Cancelled)
            };
        }
    }
}
