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

            // 1. Izračunaj hash odmah
            var hash = await CalculateHash(imageBytes);
            var extension = ".jpg";

            // 2. Koristi HASH kao ime fajla umjesto GUID-a!
            // Na ovaj način, ista slika će se uvijek zvati isto na disku.
            string fileName = $"{hash}{extension}";
            string folderPath = Path.Combine(_environment.WebRootPath, "uploads", subFolder);

            if (!Directory.Exists(folderPath))
                Directory.CreateDirectory(folderPath);

            string fullPath = Path.Combine(folderPath, fileName);

            // 3. Provjeri postoji li fajl fizički na disku prije pisanja
            if (!File.Exists(fullPath))
            {
                await File.WriteAllBytesAsync(fullPath, imageBytes);
            }

            return new TenderImageDTO
            {
                ImageUrl = $"/uploads/{subFolder}/{fileName}",
                FileName = fileName,
                IsPrimary = isPrimary,
                ImageHash = hash 
            };
        }

        public async Task<TenderImageDTO> UploadImageAsync(IFormFile file, string subFolder, bool isPrimary = false)
        {
            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            return await UploadImageAsync(ms.ToArray(), subFolder, isPrimary);
        }
        public async  Task<string> CalculateHash(byte[] data)
        {
            return await Task.Run(() =>
            {
                using var sha256 = System.Security.Cryptography.SHA256.Create();
                var hashBytes = sha256.ComputeHash(data);
                return BitConverter.ToString(hashBytes).Replace("-", "").ToLower();
            });
        }


        public void DeleteImage(string relativePath)
        {
            if (string.IsNullOrEmpty(relativePath)) return;

            var fullPath = Path.Combine(_environment.WebRootPath, relativePath.TrimStart('/'));

            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
            }
        }
    }
}