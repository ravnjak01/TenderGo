using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.Requests;
using TenderGo.Services.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface ITenderService:IBaseService<TenderDTO,TenderInsertRequest,TenderUpdateRequest>
    {
        Task<IEnumerable<TenderDTO>> GetTendersByCategory(int id);
       Task<IEnumerable<TenderDTO>> GetClosedTenders();
        Task<IEnumerable<TenderDTO>> GetActiveTenders();
        Task<Tender> GetTenderByIdAsync(int id);




    }
}
