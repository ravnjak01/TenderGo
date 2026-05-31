public class AdminUserTenderReportModel
{
    public string UserName { get; set; }
    public List<TenderWithOffers> Tenders { get; set; }
}

public class TenderWithOffers
{
    public string TenderTitle { get; set; }
    public string Status { get; set; }
    public DateTime CreatedAt { get; set; }

    public List<OfferItem> Offers { get; set; }
}

public class OfferItem
{
    public string BidderName { get; set; }
    public decimal Amount { get; set; }
    public string Status { get; set; }
    public DateTime Date { get; set; }
}