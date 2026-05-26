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
        // 🌟 NOVI ENDPOINT: Generisanje zbirnog izvještaja o tenderima i ponudama za korisnika
        [HttpGet("user/{userId}/tenders")]
        public async Task<IActionResult> DownloadUserTendersReport(string userId)
        {
            var currentUserId = _authService.GetCurrentUserId();
            
            // 🔒 Opcionalno: Dopusti preuzimanje samo Adminu ili korisniku koji je vlasnik profila
            // Ako u sistemu imaš ugrađen Role management preko tokena, možeš otkomentarisati provjeru uloga
          //  if (currentUserId != userId)
            //{
                // Primjer provjere ako želiš striktno admina (prilagodi svom User objektu ili Claimovima):
             //   throw new ForbiddenException("Nemate dozvolu za pristup izvještaju ovog korisnika.");
            //}

            // 1. Dobavi osnovne podatke o korisniku (da imamo ime za naslov izvještaja)
            var user = await _context.Users
                .Where(u => u.Id == userId)
                .Select(u => new { u.FirstName, u.LastName })
                .FirstOrDefaultAsync();

            if (user == null)
            {
                return NotFound($"Korisnik sa ID-jem {userId} ne postoji.");
            }

            // 2. Povuci sve tendere tog korisnika zajedno sa ugniježđenim ponudama (Bids) i ponuđačima
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

            // 3. Spakuj sve podatke u glavni model izvještaja
            var reportModel = new AdminUserTenderReportModel
            {
                UserName = $"{user.FirstName} {user.LastName}",
                Tenders = tendersData
            };

            // 4. Proslijedi podatke u QuestPDF dokument i generiši bajtove
            var document = new AdminUserTenderReportDocument(reportModel);
            byte[] pdfBytes = document.GeneratePdf();

            // 5. Vrati generisani fajl klijentu (Flutteru)
            string fileName = $"Izvjestaj_Tenderi_{user.FirstName}_{user.LastName}.pdf";
            return File(pdfBytes, "application/pdf", fileName);
        }

        
    }
}
