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
    public interface ITenderService:IReadService<TenderDTO>,IWriteService<TenderDTO,TenderInsertRequest,TenderUpdateRequest>
    {
        Task<IEnumerable<TenderDTO>> GetTendersByCategory(int id);
       Task<IEnumerable<TenderDTO>> GetClosedTenders();
        Task<IEnumerable<TenderDTO>> GetActiveTenders();
        Task<IEnumerable<TenderDTO>> GetCancelledTenders();

        Task<List<TenderDTO>> GetTendersByUser(string userId);

        Task<TenderDTO> Cancel(int tenderId);
        Task<TenderDTO> Award(int id, int bidId);
        Task<List<string>> AllowedActions(int id);
        BaseState CreateState(TenderStatus status);
        Task<PagedResult<TenderDTO>>SearchAsync(TenderSearchRequest request);
        Task<bool> LogUserActivityAsync(string activityType, int? tenderId, string? searchQuery, int? durationSeconds = null);

        Task<bool> ToggleBookmarkAsync(string userId, int tenderId);
        Task<IEnumerable<TenderDTO>> GetBookmarkedTendersAsync(string userId);

    }
}
