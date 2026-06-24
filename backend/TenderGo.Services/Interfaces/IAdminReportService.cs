using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Interfaces
{
    public interface IAdminReportService
    {
        Task<AdminReportOverviewDTO> GetAdminReportOverview();
        Task<byte[]>GenerateReportAsync(AdminReportRequest request);

        Task<(byte[] PdfBytes, string FileName)>
            GenerateUserTendersReportAsync(string userId);
    }
}
