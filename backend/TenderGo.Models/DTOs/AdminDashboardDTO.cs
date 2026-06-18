using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
    public class AdminDashboardDTO
    {
        public int TotalUsers { get; set; }

        public int ActiveTenders { get; set; }

        public int TotalCategories { get; set; }

        public int TotalLocations { get; set; }

        public List<ActivityDTO> RecentActivities { get; set; } = [];
    }
}
