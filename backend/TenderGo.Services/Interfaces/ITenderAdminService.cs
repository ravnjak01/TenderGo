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
        Task<PagedResult<AdminTenderDTO>> GetAllTendersAsync(AdminTenderSearchRequest request);
        Task<PagedResult<AdminTenderDTO>> AdminSearchAsync(AdminTenderSearchRequest request);
    }
}
