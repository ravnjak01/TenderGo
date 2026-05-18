using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
namespace TenderGo.Models.DTOs
{
    public class TenderDTO: IHasId
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; } = string.Empty;
        public decimal MaxBudget { get; set; }
        public DateTime Deadline { get; set; }

        public string CreatedByUserId { get; set; }

        public string CreatedByFullname { get; set; }
        public TenderStatus Status {get; set;} 

        public int TotalBids { get; set; }
        public virtual ICollection<TenderImageDTO> Images { get; set; } = new List<TenderImageDTO>();

        public LocationDTO Location { get; set; } = null!;
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;


    //zadnje popravio location i tenderdto tendercardmodel
        public DateTime PostedAt { get; set; }
        public string? ProfileImageUrl { get; set; }

    }
}