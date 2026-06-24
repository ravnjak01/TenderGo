public class AdminUserTenderReportModel
{
    public string UserName { get; set; } = string.Empty;
    public List<TenderWithOffers> Tenders { get; set; } = new();
}

public class TenderWithOffers
{
    public string TenderTitle { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    public decimal MaxBudget { get; set; }
    public DateTime Deadline { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string LocationName { get; set; } = string.Empty;

    public List<OfferItem> Offers { get; set; } = new();
}

public class OfferItem
{
    public string BidderName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime Date { get; set; }

    public int DeliveryDays { get; set; }
}