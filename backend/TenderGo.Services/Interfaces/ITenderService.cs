using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.Requests;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Services.StateMachines.TenderStates;

namespace TenderGo.Services.Interfaces
{
    public interface ITenderService:IReadService<TenderDTO>,IWriteService<TenderDTO,TenderInsertRequest, TenderUpdateRequest>
    {
        Task<PagedResult<TenderDTO>> GetTendersByCategory(int id, PagedSearchRequest request);
        Task<PagedResult<TenderDTO>> GetClosedTenders(PagedSearchRequest request);
        Task<PagedResult<TenderDTO>> GetActiveTenders(PagedSearchRequest request);
        Task<PagedResult<TenderDTO>> GetCancelledTenders(PagedSearchRequest request);
        Task<PagedResult<TenderDTO>> GetTendersByUser(string userId, PagedSearchRequest request);

        Task<TenderDTO> Cancel(int tenderId,TenderCancelRequest request);
        Task<TenderDTO> Award(int id, int bidId);
        Task<List<string>> AllowedActions(int id);
        BaseState CreateState(TenderStatus status);
        Task<PagedResult<TenderDTO>>SearchAsync(TenderSearchRequest request);
        Task<bool> LogUserActivityAsync(string activityType, int? tenderId, string? searchQuery, int? durationSeconds = null);

        Task<bool> ToggleBookmarkAsync(string userId, int tenderId);
        Task<IEnumerable<TenderDTO>> GetBookmarkedTendersAsync(string userId);

    }
}
