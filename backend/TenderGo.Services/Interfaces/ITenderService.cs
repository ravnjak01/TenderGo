using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.Requests;
using TenderGo.Models.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface ITenderService:IReadService<TenderDTO>,IWriteService<TenderDTO,TenderInsertRequest,TenderUpdateRequest>
    {
        Task<IEnumerable<TenderDTO>> GetTendersByCategory(int id);
       Task<IEnumerable<TenderDTO>> GetClosedTenders();
        Task<IEnumerable<TenderDTO>> GetActiveTenders();
        Task<List<TenderDTO>> GetTendersByUser(string userId);

        Task<TenderDTO> Cancel(int tenderId);
        Task<TenderDTO> Activate(int tenderId);
        Task<TenderDTO> Award(int id, int bidId);

    }
}
