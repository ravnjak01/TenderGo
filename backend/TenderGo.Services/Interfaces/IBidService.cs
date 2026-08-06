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
    public interface IBidService:IReadService<BidDTO,PagedSearchRequest>
    {

        Task<BidDTO>Withdraw(int bidId);
        Task<PagedResult<BidDTO>> GetBidsForTender(int tenderId,PagedSearchRequest request);
        Task<List<string>> AllowedActions(int bidId);
        Task<PagedResult<BidDTO>> GetBidsByUser(string userId, PagedSearchRequest request);
        Task<BidDTO> Cancel(int bidId);
        Task<BidDTO> Insert(BidInsertRequest request);

    }
}
