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

        private static readonly HashSet<string> AllowedMimeTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "image/jpeg",
            "image/png",
            "image/gif",
            "image/webp",
            "image/bmp"
        };

        private static readonly List<(int Offset, byte[] Signature, string Format)> MagicSignatures = new()
        {
            (0, new byte[] { 0xFF, 0xD8, 0xFF },             "JPEG"),
            (0, new byte[] { 0x89, 0x50, 0x4E, 0x47,
                             0x0D, 0x0A, 0x1A, 0x0A },       "PNG"),
            (0, new byte[] { 0x47, 0x49, 0x46, 0x38 },       "GIF"),  
            (0, new byte[] { 0x52, 0x49, 0x46, 0x46 },       "WEBP"), 
            (0, new byte[] { 0x42, 0x4D },                   "BMP"),
        };

        public ImageService(IWebHostEnvironment environment)
        {
            _environment = environment;
        }

        public async Task<TenderImageDTO> UploadImageAsync(
            byte[] imageBytes, string subFolder, bool isPrimary = false)
        {
            if (imageBytes == null || imageBytes.Length == 0)
                throw new ArgumentException("Niz bajtova je prazan.");

            if (!IsValidImage(imageBytes))
                throw new ArgumentException("Fajl nije validna slika (nevažeći magic bytes).");

            var hash = await CalculateHash(imageBytes);
            var extension = DetectExtension(imageBytes);
            string fileName = $"{hash}{extension}";
            var webRoot = _environment.WebRootPath;
            if (string.IsNullOrWhiteSpace(webRoot))
            {
                webRoot = Path.Combine(_environment.ContentRootPath, "wwwroot");
            }

            string folderPath = Path.Combine(webRoot, "uploads", subFolder);

            if (!Directory.Exists(folderPath))
                Directory.CreateDirectory(folderPath);

            string fullPath = Path.Combine(folderPath, fileName);

            if (!File.Exists(fullPath))
                await File.WriteAllBytesAsync(fullPath, imageBytes);

            return new TenderImageDTO
            {
                ImageUrl = $"/uploads/{subFolder}/{fileName}",
                FileName = fileName,
                IsPrimary = isPrimary,
                ImageHash = hash
            };
        }

        public async Task<TenderImageDTO> UploadImageAsync(
            IFormFile file, string subFolder, bool isPrimary = false)
        {
            if (!AllowedMimeTypes.Contains(file.ContentType))
                throw new ArgumentException(
                    $"Nedozvoljeni tip fajla: {file.ContentType}. " +
                    $"Dozvoljeni tipovi: {string.Join(", ", AllowedMimeTypes)}");

            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            byte[] bytes = ms.ToArray();

            if (!IsValidImage(bytes))
                throw new ArgumentException(
                    "Sadržaj fajla ne odgovara deklarisanom tipu (magic bytes provjera nije prošla).");

            string detectedMime = DetectMimeType(bytes);
            if (!string.IsNullOrEmpty(detectedMime) &&
                !detectedMime.Equals(file.ContentType, StringComparison.OrdinalIgnoreCase))
                throw new ArgumentException(
                    $"MIME tip '{file.ContentType}' ne odgovara stvarnom formatu fajla '{detectedMime}'.");

            return await UploadImageAsync(bytes, subFolder, isPrimary);
        }

        public async Task<string> CalculateHash(byte[] data)
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
            var fullPath = Path.Combine(
                _environment.WebRootPath, relativePath.TrimStart('/'));
            if (File.Exists(fullPath))
                File.Delete(fullPath);
        }

      
        public bool IsValidImage(byte[] fileBytes)
        {
            if (fileBytes == null || fileBytes.Length < 12) return false;

            foreach (var (offset, signature, format) in MagicSignatures)
            {
                if (fileBytes.Length < offset + signature.Length) continue;

                bool matches = fileBytes
                    .Skip(offset)
                    .Take(signature.Length)
                    .SequenceEqual(signature);

                if (!matches) continue;

                if (format == "WEBP")
                {
                    var webpMarker = new byte[] { 0x57, 0x45, 0x42, 0x50 };
                    bool isWebp = fileBytes.Skip(8).Take(4).SequenceEqual(webpMarker);
                    if (isWebp) return true;
                    continue; 
                }

                return true;
            }

            return false;
        }

        private static string DetectMimeType(byte[] bytes)
        {
            if (bytes.Length >= 3 &&
                bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
                return "image/jpeg";

            if (bytes.Length >= 8 &&
                bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E &&
                bytes[3] == 0x47 && bytes[4] == 0x0D && bytes[5] == 0x0A &&
                bytes[6] == 0x1A && bytes[7] == 0x0A)
                return "image/png";

            if (bytes.Length >= 4 &&
                bytes[0] == 0x47 && bytes[1] == 0x49 &&
                bytes[2] == 0x46 && bytes[3] == 0x38)
                return "image/gif";

            if (bytes.Length >= 12 &&
                bytes[0] == 0x52 && bytes[1] == 0x49 &&
                bytes[2] == 0x46 && bytes[3] == 0x46 &&
                bytes[8] == 0x57 && bytes[9] == 0x45 &&
                bytes[10] == 0x42 && bytes[11] == 0x50)
                return "image/webp";

            if (bytes.Length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D)
                return "image/bmp";

            return string.Empty;
        }

        private static string DetectExtension(byte[] bytes)
        {
            return DetectMimeType(bytes) switch
            {
                "image/jpeg" => ".jpg",
                "image/png" => ".png",
                "image/gif" => ".gif",
                "image/webp" => ".webp",
                "image/bmp" => ".bmp",
                _ => ".jpg"   
            };
        }
    }
}
