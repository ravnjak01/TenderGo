namespace TenderGo.Contracts
{
    public class BidCreatedEvent
    {
        public int TenderId { get; set; }
        public string OwnerUserId { get; set; } = string.Empty;
        public decimal OfferedPrice { get; set; }
        public string TenderTitle { get; set; } = string.Empty;
    }
}

