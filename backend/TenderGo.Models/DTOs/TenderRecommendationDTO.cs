namespace TenderGo.Models.DTOs;

public class RecommendationResultDTO
{
    public string? Message { get; set; }
    public List<TenderRecommendationDTO> Recommendations { get; set; } = new();
}

public class TenderRecommendationDTO
{
    public int TenderId { get; set; }
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public decimal MaxBudget { get; set; }
    public DateTime Deadline { get; set; }
    public string Status { get; set; } = null!;
    public string? Category { get; set; }
    public string? Country { get; set; }
    public string? City { get; set; }
    public string? Region { get; set; }
    public string? LocationName { get; set; }
    public string? ThumbnailUrl { get; set; }
    public double SimilarityScore { get; set; }
    public string RecommendationReason { get; set; } = string.Empty;
    public List<string> RecommendationSignals { get; set; } = new();
}
