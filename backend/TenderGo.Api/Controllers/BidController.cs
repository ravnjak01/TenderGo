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




        [HttpPatch("{id}")]
        public override async Task<IActionResult> Update(int id, [FromBody] BidUpdateRequest request)
        {
            var result = await _bidService.Update(id, request);
            return Ok(result);
        }

      
        [HttpPatch("{id}/withdraw")]
        public async Task<ActionResult<BidDTO>> Withdraw(int id)
        {
            var result = await _bidService.Withdraw(id);
            return Ok(result);
        }


        [HttpGet("tender/{tenderId}")]
        public async Task<ActionResult<List<BidDTO>>> GetBidsForTender(int tenderId)
        {
            var bids = await _bidService.GetBidsForTender(tenderId);

            if (bids == null || !bids.Any())
                return NotFound(); 

            return Ok(bids);
        }


        [HttpGet("{id}/allowed-actions")]
        public async Task<ActionResult<List<string>>> GetAllowedActions(int id)
        {
            var actions = await _bidService.AllowedActions(id);
            return Ok(actions);
        }
    }
}




