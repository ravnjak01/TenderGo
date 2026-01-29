using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services;

namespace TenderGo.Api.Controllers
{

    [Route("api/bid")]
    [Authorize(Roles = "User")]
    public class BidController : BaseController<BidDTO, Bid, BidInsertRequest, BidUpdateRequest>
    {
        private readonly IBidService _bidService;

        public BidController(IBidService bidService, ILogger<BidController> logger, IAuthService authservice)
       : base(bidService, logger)
        {
            _bidService = bidService;
        }


        [HttpPost("submit")]
        public async Task<ActionResult<BidDTO>> SubmitBid(BidInsertRequest request)
        {
            var result = await _bidService.SubmitBidAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
        }

        [HttpPatch("accept/{bidId}")]
        public async Task<IActionResult> AcceptBid(int bidId)
        {
            await _bidService.AcceptBidAsync(bidId);
            return NoContent();
        }

        [HttpPatch(" reject/{bidId}")]
        public async Task<IActionResult> RejectBid(int bidId)
        {
            await _bidService.RejectBidAsync(bidId);
            return NoContent();
        }

    }
}




