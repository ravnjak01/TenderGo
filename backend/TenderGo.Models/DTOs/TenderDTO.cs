namespace TenderGo.Services.DTOs
{
    public class TenderDTO
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal MaxBudget { get; set; }
        public DateTime Deadline { get; set; }
        public string Status { get; set; } = string.Empty; // Npr. "Open", "Closed"

        // Dodatno: Možeš dodati i broj ponuda da Flutter odmah prikaže npr. "5 ponuda"
        public int TotalBids { get; set; }

        // Ako je već neko ponudio najnižu cijenu, pošalji i nju
        public decimal? CurrentLowestBid { get; set; }
    }
}