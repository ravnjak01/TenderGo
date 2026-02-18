using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{

    [Route("api/bid")]
    [Authorize(Roles = "User")]
    public class BidController : BaseController<BidDTO, Bid, BidInsertRequest, BidUpdateRequest>
    {
        private readonly IBidService _bidService;

        public BidController(IBidService bidService, ILogger<BidController> logger)
       : base(bidService, bidService, logger)
        {
            _bidService = bidService;
        }


     

        [HttpPatch("{tenderId}/accept/{bidId}")]
        public async Task<IActionResult> AcceptBid(int tenderId,int bidId)
        {
            await _bidService.AcceptBid(tenderId,bidId);
            return NoContent();
        }

        [HttpPatch("reject/{bidId}")]
        public async Task<IActionResult> RejectBid(int bidId)
        {
            await _bidService.RejectBidAsync(bidId);
            return NoContent();
        }

    }
}




