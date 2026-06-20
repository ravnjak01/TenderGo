using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Interfaces
{
    public interface ITenderAdminService
    {
        Task<List<AdminTenderDTO>> GetAllTendersAsync();
        Task<PagedResult<TenderDTO>> AdminSearchAsync(AdminTenderSearchRequest request);
    }
}
