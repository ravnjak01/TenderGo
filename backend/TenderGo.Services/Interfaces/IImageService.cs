using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface IImageService
    {
        Task<TenderImageDTO> UploadImageAsync(IFormFile file, string subFolder, bool isPrimary = false);
        void DeleteImage(string relativePath);
    }
}
