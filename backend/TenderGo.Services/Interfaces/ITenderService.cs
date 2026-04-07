using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.Requests;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;

namespace TenderGo.Services.Interfaces
{
    public interface ITenderService:IReadService<TenderDTO>,IWriteService<TenderDTO,TenderInsertRequest,TenderUpdateRequest>
    {
        Task<IEnumerable<TenderDTO>> GetTendersByCategory(int id);
       Task<IEnumerable<TenderDTO>> GetClosedTenders();
        Task<IEnumerable<TenderDTO>> GetActiveTenders();
        Task<IEnumerable<TenderDTO>> GetDraftTenders();
        Task<List<TenderDTO>> GetTendersByUser(string userId);

        Task<TenderDTO> Cancel(int tenderId);
        Task<TenderDTO> Publish(int tenderId);
        Task<TenderDTO> SaveDraft(TenderInsertRequest request);
        Task<TenderDTO> Award(int id, int bidId);
        Task<List<string>> AllowedActions(int id);

    }
}
