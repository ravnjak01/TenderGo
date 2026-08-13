using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class AdminReportService : IAdminReportService
    {
        private readonly TenderGoContext _context;
        private readonly IAuthService _authService;

        public AdminReportService(TenderGoContext context,IAuthService authService)
        {
            _context = context;
            _authService = authService;
        }

        public async Task<(byte[] PdfBytes, string FileName)> GenerateUserTendersReportAsync(string userId)
        {
            var user = await _context.Users
                .Where(u => u.Id == userId)
                .Select(u => new { u.FirstName, u.LastName })
                .FirstOrDefaultAsync();

            if (user == null)
            {
                throw new NotFoundException("User",userId);
            }

            var tendersData = await _context.Tenders
                .Where(t => t.CreatedByUserId == userId)
                .Select(t => new TenderWithOffers
                {
                    TenderTitle = t.Title,
                    Status = t.Status.ToString(),
                    CreatedAt = t.CreatedAt,

                    MaxBudget = t.MaxBudget,
                    Deadline = t.Deadline,
                    CategoryName = t.Category != null ? t.Category.Name : "N/A", 
                    LocationName = t.Location != null ? t.Location.Name : "N/A", 

                    Offers = t.Bids.Select(b => new OfferItem
                    {
                        BidderName = b.SubmittedByUser.FirstName + " " + b.SubmittedByUser.LastName,
                        Amount = b.OfferedPrice,
                        Status = b.Status.ToString(),
                        Date = b.SubmittedAt,

                        DeliveryDays = b.DeliveryDays 
                    }).ToList()
                })
                .ToListAsync();

            var reportModel = new AdminUserTenderReportModel
            {
                UserName = $"{user.FirstName} {user.LastName}",
                Tenders = tendersData
            };

            var document = new AdminUserTenderReportDocument(reportModel);
            byte[] pdfBytes = document.GeneratePdf();

            string fileName = $"Izvjestaj_Tenderi_{user.FirstName}_{user.LastName}.pdf";

            return (pdfBytes, fileName);
        }

        public async Task<byte[]> GenerateReportAsync(AdminReportRequest request)
        {
            if (request.From > request.To)
            {
                throw new UserException("Početni datum ne može biti poslije završnog datuma.");
            }

            DateTime prikazniFrom = request.From;
            DateTime prikazniTo = request.To;

            DateTime lokalniFrom = request.From.Date;
            DateTime lokalniTo = request.To.Date.AddDays(1).AddTicks(-1);

            DateTime utcFrom = lokalniFrom.ToUniversalTime();
            DateTime utcTo = lokalniTo.ToUniversalTime();

           
      
            var tenders = await _context.Tenders
                .Include(t => t.Location)
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .AsNoTracking()
                .Where(t =>
                    t.LocationId == request.LocationId &&
                    t.CreatedAt >= utcFrom &&
                    t.CreatedAt <= utcTo)
                .OrderByDescending(t => t.CreatedAt)
                .ToListAsync();

            var document = new AdminTenderReportDocumentByLocationDate(
                tenders,
                prikazniFrom,
                prikazniTo);

            return document.GeneratePdf();
        }

        public async Task<AdminReportOverviewDTO> GetAdminReportOverview()
        {
            var totalTenders = await _context.Tenders.CountAsync();
            var completedTenders = await _context.Tenders.CountAsync(t => t.Status == TenderStatus.Awarded);

            return new AdminReportOverviewDTO
            {
                TotalTenderValue = await _context.Tenders
                .Where(t=>t.Status == TenderStatus.Awarded)
                .SumAsync(t => t.WinningBid.OfferedPrice),
                TenderRealizationPercentage = totalTenders == 0 ? 0 : (double)completedTenders / totalTenders * 100,
                CancelledTenderCount = await _context.Tenders.CountAsync(t => t.Status == TenderStatus.Cancelled)
            };
        }
    }
}
