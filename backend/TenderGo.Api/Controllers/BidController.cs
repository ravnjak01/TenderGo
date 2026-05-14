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
    [Authorize(Roles = AppRoles.Admin + "," + AppRoles.User)]
    public class BidController : ControllerBase
    {
        private readonly IBidService _bidService;

        public BidController(IBidService bidService, ILogger<BidController> logger)
      // : base(bidService, bidService, logger)
        {
            _bidService = bidService;
        }





        //[HttpPatch("{id}")]
        //public override async Task<IActionResult> Update(int id, [FromBody] BidUpdateRequest request)
        //{
        //    var result = await _bidService.Update(id, request);
        //    return Ok(result);
        //}
        [HttpGet("{id}")]
        public async Task<ActionResult<BidDTO>> GetById(int id)
        {
            return Ok(await _bidService.GetById(id));
        }

        [HttpPost]
        public async Task<ActionResult<BidDTO>> Insert([FromBody] BidInsertRequest request)
        {
            var result = await _bidService.Insert(request);
            return Ok(new {message="Bid sent successfully"});
        }

        [HttpPut("{id}/cancel")]
        public async Task<ActionResult<BidDTO>> Cancel(int id)
        {
            var result = await _bidService.Cancel(id);
            return Ok(result);
        }

        [HttpPatch("{id}/withdraw")]
        public async Task<ActionResult<BidDTO>> Withdraw(int id)
        {
            var result = await _bidService.Withdraw(id);
            return Ok(result);
        }

        [HttpGet("my-bids")]
        [Authorize]
        public async Task<ActionResult<List<BidDTO>>> GetMyBids()
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var bids = await _bidService.GetBidsByUser(userId);
            return Ok(bids);
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




