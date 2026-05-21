using TenderGo.Models.DTOs;
using TenderGo.Models.ENUMs;

public class BidDTO : IHasId
{
    public int Id { get; set; }
    public int TenderId { get; set; }
    public string TenderTitle { get; set; } = string.Empty;
    public string SubmittedByUserId { get; set; } = string.Empty;
    public string SubmittedByUserName { get; set; } = string.Empty;
    public decimal OfferedPrice { get; set; }
    public DateTime SubmittedAt { get; set; }
    public ApplicationStatus Status { get; set; } 
    public string? Proposal { get; set; }
    public int DeliveryDays { get; set; }
}