using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.DTOs
{
    public class BidDTO:IHasId
    {
        public int Id { get; set; }

        public int TenderId { get; set; }
        // Umjesto cijelog objekta Tender, često je korisno poslati samo Naslov
        public string TenderTitle { get; set; }

        public string SubmittedByUserId { get; set; }
        // Možeš dodati i ime korisnika ako ti zatreba za prikaz
        public string? SubmittedByUserName { get; set; }

        public decimal OfferedPrice { get; set; }
        public DateTime SubmittedAt { get; set; }
    }
}
