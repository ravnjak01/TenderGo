using TenderGo.Models.DTOs;

namespace TenderGo.Services.Interfaces;

public interface IRecommendationService
{
    Task<RecommendationResultDTO?> GetSimilarAsync(int tenderId, int topN = 10);
    Task<RecommendationResultDTO> GetForCurrentUserAsync(string userId, int topN = 10);
}
