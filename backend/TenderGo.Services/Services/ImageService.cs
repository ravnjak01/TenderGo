using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using TenderGo.Models.DTOs; // Obavezno dodaj namespace za DTO
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

        public async Task<TenderImageDTO> UploadImageAsync(IFormFile file, string subFolder, bool isPrimary = false)
        {
            if (file == null || file.Length == 0)
                throw new ArgumentException("Fajl je prazan.");

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!allowedExtensions.Contains(extension))
                throw new ArgumentException("Nepodržan format slike.");

            // Putanja: wwwroot/uploads/subFolder
            string folderPath = Path.Combine(_environment.WebRootPath, "uploads", subFolder);

            if (!Directory.Exists(folderPath))
                Directory.CreateDirectory(folderPath);

            // Generisanje jedinstvenog imena
            string fileName = $"{Guid.NewGuid()}{extension}";
            string fullPath = Path.Combine(folderPath, fileName);

            using (var stream = new FileStream(fullPath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Kreiranje i vraćanje DTO objekta
            return new TenderImageDTO
            {
                ImageUrl = $"/uploads/{subFolder}/{fileName}",
                FileName = fileName,
                IsPrimary = isPrimary
            };
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