using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface IAdminDashboardService
    {
        Task<AdminDashboardDTO> GetDashboardAsync();
        Task<List<ActivityDTO>> GetRecentActivitiesAsync();
    }
}
