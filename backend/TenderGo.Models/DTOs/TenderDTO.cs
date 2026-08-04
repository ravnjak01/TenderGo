using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
namespace TenderGo.Models.DTOs
{
    public class TenderDTO : AdminTenderDTO
    {
        public string? Description { get; set; } = string.Empty;
        public string CreatedByUserId { get; set; } = string.Empty;
        public int TotalBids { get; set; }
        public virtual ICollection<TenderImageDTO> Images { get; set; } = new List<TenderImageDTO>();

        public LocationDTO Location { get; set; } = null!;
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;

        public DateTime? CancelledAt { get; set; }
        public string? CancelledByUserId { get; set; }
        public string? CancellationReason { get; set; }
        public DateTime PostedAt { get; set; }
    }
}