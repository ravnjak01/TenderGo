using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Api.Controllers
{
    [Route("api/bid")]
    [ApiController] 
    [Authorize(Roles = AppRoles.Admin + "," + AppRoles.User)]
    public class BidController : ControllerBase
    {
        private readonly IBidService _bidService;

        public BidController(IBidService bidService)
        {
            _bidService = bidService;
        }

  

        [HttpPost]
        public async Task<IActionResult> Insert([FromBody] BidInsertRequest request)
        {
            var result = await _bidService.Insert(request);
            return Ok(result);
        }

     

        [HttpPatch("{id}/withdraw")]
        public async Task<IActionResult> Withdraw(int id)
        {
            var result = await _bidService.Withdraw(id);
            return Ok(result);
        }

        [HttpGet("my-bids")]
        public async Task<IActionResult> GetMyBids([FromQuery] PagedSearchRequest request)
        {

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userId))
                return Unauthorized(); 

            var bids = await _bidService.GetBidsByUser(userId,request);
            return Ok(bids);
        }

        [HttpGet("tender/{tenderId}")]
        public async Task<IActionResult> GetBidsForTender(int tenderId, [FromQuery]  PagedSearchRequest request)
        {
            var bids = await _bidService.GetBidsForTender(tenderId,request);
            return Ok(bids);
        }

        [HttpGet("{id}/allowed-actions")]
        public async Task<IActionResult> GetAllowedActions(int id)
        {
            var actions = await _bidService.AllowedActions(id);
            return Ok(actions);
        }
    }
}