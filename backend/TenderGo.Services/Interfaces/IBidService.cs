using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;
using TenderGo.Services.Services;

namespace TenderGo.Services.Interfaces
{
    public interface IBidService:IBaseService<BidDTO, BidCreateRequest, BidCreateRequest>
    {

         Task<Bid> SubmitBidAsync(string userId, BidCreateRequest request);
    Task<IEnumerable<Bid>> GetBidsForTenderAsync(int tenderId);
}
}
