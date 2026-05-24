namespace TenderGo.Contracts
{
    public class TenderExpiredEvent
    {
        public int TenderId { get; set; }
        public string TenderTitle { get; set; } = string.Empty;
        public string OwnerUserId { get; set; } = string.Empty;
        public DateTime ExpiredAt { get; set; }
    }
}
