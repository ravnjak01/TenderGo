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
    public interface ITenderService:IReadService<TenderDTO,TenderSearchRequest>,IWriteService<TenderDTO,TenderInsertRequest, TenderUpdateRequest>
    {
        Task<PagedResult<TenderDTO>> GetMyTenders(string userId, PagedSearchRequest request);

        Task<TenderDTO> Cancel(int tenderId,TenderCancelRequest request);
        Task<TenderDTO> Award(int id, int bidId);
        Task<List<string>> AllowedActions(int id);
        BaseState CreateState(TenderStatus status);
        Task<bool> LogUserActivityAsync(string activityType, int? tenderId, string? searchQuery, int? durationSeconds = null);

        Task<bool> ToggleBookmarkAsync(string userId, int tenderId);
        Task<PagedResult<TenderDTO>> GetBookmarkedTendersAsync(string userId, PagedSearchRequest request);
        Task<PagedResult<AdminTenderDTO>> GetAdminTendersAsync(TenderSearchRequest request);

    }
}
