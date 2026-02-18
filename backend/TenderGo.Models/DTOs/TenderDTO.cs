using TenderGo.Models.DTOs;
using TenderGo.Models.ENUMs;
namespace TenderGo.Models.DTOs
{
    public class TenderDTO: IHasId
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal MaxBudget { get; set; }
        public DateTime Deadline { get; set; }

        public string CreatedByUserId { get; set; }

        public string CreatedByFullname { get; set; }
        public TenderStatus Status {get; set;} // Npr. "Open", "Closed"

        // Dodatno: Možeš dodati i broj ponuda da Flutter odmah prikaže npr. "5 ponuda"
        public int TotalBids { get; set; }

        // Ako je već neko ponudio najnižu cijenu, pošalji i nju
        public decimal? CurrentLowestBid { get; set; }
    }
}