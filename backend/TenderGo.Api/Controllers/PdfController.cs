using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Net.NetworkInformation;
using TenderGo.Api.Database;
using TenderGo.Models.ENUMs;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services;
using QuestPDF.Fluent;
using Microsoft.AspNetCore.Authorization;
using TenderGo.Services.Services.Exceptions;
using TenderGo.Models.Entities;

namespace TenderGo.Api.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class PdfController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly TenderGoContext _context;

        public PdfController(IAuthService authService,TenderGoContext context)
        {
            _authService = authService;
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

            if (bid == null)
            {
                throw new NotFoundException("Accepted offer not found", new { OfferId = id });
            }

            var currentUser=_authService.GetCurrentUserId();

            bool isOwner=bid.Tender.CreatedByUserId==currentUser;
            bool isBidder=bid.SubmittedByUserId==currentUser;


            if(!isOwner && !isBidder)
            {
                throw new ForbiddenException("You dont have permission to access this document");
            }

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


        [Authorize(Roles =AppRoles.Admin)]
        [HttpGet("user/{userId}/tenders")]
        public async Task<IActionResult> DownloadUserTendersReport(string userId)
        {
            var currentUserId = _authService.GetCurrentUserId();
            
            var user = await _context.Users
                .Where(u => u.Id == userId)
                .Select(u => new { u.FirstName, u.LastName })
                .FirstOrDefaultAsync();

            if (user == null)
            {
                return NotFound($"Korisnik sa ID-jem {userId} ne postoji.");
            }

            var tendersData = await _context.Tenders
                .Where(t => t.CreatedByUserId == userId)
                .Select(t => new TenderWithOffers
                {
                    TenderTitle = t.Title,
                    Status = t.Status.ToString(),
                    CreatedAt = t.CreatedAt,
                    Offers = t.Bids.Select(b => new OfferItem
                    {
                        BidderName = b.SubmittedByUser.FirstName + " " + b.SubmittedByUser.LastName,
                        Amount = b.OfferedPrice,
                        Status = b.Status.ToString(),
                        Date = b.SubmittedAt
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
            return File(pdfBytes, "application/pdf", fileName);
        }

        
    }
}
