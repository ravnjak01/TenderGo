using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using TenderGo.Models.DTOs; 
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class ImageService : IImageService
    {
        private readonly IWebHostEnvironment _environment;

        public ImageService(IWebHostEnvironment environment)
        {
            _environment = environment;
        }

        public async Task<TenderImageDTO> UploadImageAsync(byte[] imageBytes, string subFolder, bool isPrimary = false)
        {
            if (imageBytes == null || imageBytes.Length == 0)
                throw new ArgumentException("Niz bajtova je prazan.");

            var extension = ".jpg"; // Možeš dodati logiku za detekciju tipa, ali .jpg je siguran default
            string folderPath = Path.Combine(_environment.WebRootPath, "uploads", subFolder);

            if (!Directory.Exists(folderPath))
                Directory.CreateDirectory(folderPath);

            string fileName = $"{Guid.NewGuid()}{extension}";
            string fullPath = Path.Combine(folderPath, fileName);

            await File.WriteAllBytesAsync(fullPath, imageBytes);

            return new TenderImageDTO
            {
                ImageUrl = $"/uploads/{subFolder}/{fileName}",
                FileName = fileName,
                IsPrimary = isPrimary
            };
        }

        public async Task<TenderImageDTO> UploadImageAsync(IFormFile file, string subFolder, bool isPrimary = false)
        {
            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            return await UploadImageAsync(ms.ToArray(), subFolder, isPrimary);
        }

        public void DeleteImage(string relativePath)
        {
            if (string.IsNullOrEmpty(relativePath)) return;

            // Pretvaramo relativnu putanju (/uploads/...) u fizičku na disku
            var fullPath = Path.Combine(_environment.WebRootPath, relativePath.TrimStart('/'));

            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
            }
        }
    }
}