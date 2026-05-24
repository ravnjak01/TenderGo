namespace TenderGo.Contracts
{
    public class TenderAwardedEvent
    {
        public int TenderId { get; set; }
        public string TenderTitle { get; set; } = string.Empty;
        public string WinnerUserId { get; set; } = string.Empty;
        public List<string> OtherUserIds { get; set; } = new();
    }
}
