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
    public interface IBidService:IReadService<BidDTO>,IWriteService<BidDTO, BidInsertRequest, BidUpdateRequest>
    {

        Task RejectBidAsync(int bidId);
        Task AcceptBid(int tenderId, int bidId);
        Task<List<BidDTO>> GetBidsForTender(int tenderId);
    }
}
