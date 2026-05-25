using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Net.NetworkInformation;
using TenderGo.Api.Database;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services;
using QuestPDF.Fluent;
using Microsoft.AspNetCore.Authorization;

namespace TenderGo.Api.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class PdfController : ControllerBase
    {
        private readonly IBidService _bidService;
        private readonly TenderGoContext _context;

        public PdfController(IBidService bidService,TenderGoContext context)
        {
            _bidService = bidService;
            _context = context;

        }
        [HttpGet("{id}/download")]
        public async Task<IActionResult> DownloadOfferPdf(int id)
        {
            var bid = await _context.Bids
                .IgnoreQueryFilters()
                .Include(o => o.Tender)
                    .ThenInclude(t => t.CreatedByUser)
                .Include(o => o.SubmittedByUser)
                .Where(o => o.Id == id && (int)o.Status == 2)
                .FirstOrDefaultAsync();

            if (bid == null) return NotFound("Bid nije pronađen.");
            if (bid.Tender == null) return NotFound("Tender nije pronađen.");
            if (bid.Tender.CreatedByUser == null) return NotFound("Client user nije pronađen.");
            if (bid.SubmittedByUser == null) return NotFound("Submitted user nije pronađen.");

            var offerData = new OfferPdfModel
            {
                TenderName = bid.Tender.Title,
                ClientName = bid.Tender.CreatedByUser.FirstName + " " + bid.Tender.CreatedByUser.LastName,
                FirstName = bid.SubmittedByUser.FirstName,
                LastName = bid.SubmittedByUser.LastName,
                Amount = bid.OfferedPrice,
                Date = bid.SubmittedAt,
                Status = bid.Status.ToString(),
                ReferenceNumber = $"TND-{bid.TenderId:D4}-{bid.Id}"
            };

            var document = new OfferPdfDocument(offerData);
            byte[] pdfBytes = document.GeneratePdf();
            return File(pdfBytes, "application/pdf", $"{offerData.ReferenceNumber}.pdf");
        }

        
    }
}
