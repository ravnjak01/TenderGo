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
    public interface IBidService:IBaseService<BidDTO,Bid, BidInsertRequest, BidUpdateRequest>
    {

         Task<BidDTO> SubmitBidAsync( BidInsertRequest request);
        Task AcceptBidAsync(int bidId);
        Task RejectBidAsync(int bidId);

    }
}
