using TenderGo.Models.DTOs;

public class BidDTO : IHasId
{
    public int Id { get; set; }
    public int TenderId { get; set; }
    public string TenderTitle { get; set; } = string.Empty;
    public string SubmittedByUserId { get; set; } = string.Empty;
    public string SubmittedByUserName { get; set; } = string.Empty;
    public decimal OfferedPrice { get; set; }
    public DateTime SubmittedAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Proposal { get; set; }
    public int? DeliveryDays { get; set; }
}