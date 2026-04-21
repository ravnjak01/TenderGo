namespace TenderGo.Contracts
{
    public class BidCreatedEvent
    {
        public int TenderId { get; set; }
        public string OwnerUserId { get; set; }
        public decimal OfferedPrice { get; set; }
    }
}

