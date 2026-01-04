using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Services.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface ITenderService:IBaseService<TenderDTO>
    {
        IEnumerable<TenderDTO> GetAllTenders();
        IEnumerable<TenderDTO> GetTendersByCategory(int id);
        IEnumerable<TenderDTO>GetActiveTenders();
        IEnumerable<TenderDTO> GetClosedTenders(string status);



    }
}
