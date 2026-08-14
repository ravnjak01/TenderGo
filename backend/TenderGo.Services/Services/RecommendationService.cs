using Microsoft.EntityFrameworkCore;
using TenderGo.Api.Database;
using TenderGo.Data;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Recommender;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services;

public class RecommendationService : IRecommendationService
{
    private readonly TenderGoContext _db;
    private readonly RecommenderService _recommender;
    private readonly TenderVectorBuilder _builder;
    private const double MinSimilarityThreshold = 0.20;
    public RecommendationService(
        TenderGoContext db,
        RecommenderService recommender,
        TenderVectorBuilder builder)
    {
        _db = db;
        _recommender = recommender;
        _builder = builder;
    }

    public async Task<RecommendationResultDTO?> GetSimilarAsync(int tenderId, int topN = 10)
    {
        var target = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Location)
            .FirstOrDefaultAsync(t => t.Id == tenderId);

        if (target is null)
            return null;

        var allTenders = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Location)
            .Where(t => t.Id != tenderId && t.Status == TenderStatus.Open)
            .ToListAsync();

        var targetVector = _builder.Build(target);
        var candidateVectors = allTenders.Select(t => _builder.Build(t)).ToList();

        var results = _recommender.GetSimilar(targetVector, candidateVectors, topN);
        results = results.Where(r => r.Score >= MinSimilarityThreshold).ToList();

        if (!results.Any())
        {
            return new RecommendationResultDTO
            {
                Message = "No similar tenders found."
            };
        }

        var resultIds = results.Select(r => r.TenderId).ToHashSet();
        var tenderDetails = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Location)
            .Include(t => t.Images)
            .Where(t => resultIds.Contains(t.Id))
            .ToListAsync();

        var recommendations = results
            .Join(tenderDetails,
                  scored => scored.TenderId,
                  tender => tender.Id,
                  (scored, tender) =>
                  {
                      var signals = BuildSimilaritySignals(target, tender);

                      return new TenderRecommendationDTO
                      {
                          TenderId = tender.Id,
                          Title = tender.Title,
                          Description = tender.Description,
                          MaxBudget = tender.MaxBudget,
                          Deadline = tender.Deadline,
                          Status = tender.Status.ToString(),
                          Category = tender.Category?.Name,
                          Country = tender.Location?.Country,
                          City = tender.Location?.Name,
                          LocationName = tender.Location?.Name,
                          Region = tender.Location?.Region,
                          ThumbnailUrl = tender.Images.FirstOrDefault()?.ImageUrl,
                          SimilarityScore = scored.Score,
                          RecommendationSignals = signals,
                          RecommendationReason = BuildRecommendationReason(signals)
                      };
                  })
            .ToList();

        return new RecommendationResultDTO { Recommendations = recommendations };
    }

    public async Task<RecommendationResultDTO> GetForCurrentUserAsync(string userId, int topN = 10)
    {
        var biddedTenders = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Bids)
            .Where(t => t.Bids.Any(b => b.SubmittedByUserId == userId) )
            .ToListAsync();

        var userActivities = await _db.UserActivities
            .Include(a => a.Tender!).ThenInclude(t => t.Category)
            .Include(a => a.Tender!).ThenInclude(t => t.Location)
            .Where(a => a.UserId == userId)
            .OrderByDescending(a => a.Timestamp)
            .Take(20)
            .ToListAsync();

        if (!biddedTenders.Any() && !userActivities.Any())
        {
            return new RecommendationResultDTO
            {
                Message = "No history found. Start searching or viewing tenders!"
            };
        }

        var allTenders = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Location)
            .Include(t => t.Images)
            .Where(t => t.Status == TenderStatus.Open)
            .ToListAsync();

        var allVectors = allTenders.Select(t => _builder.Build(t)).ToList();
        var allTendersById = allTenders.ToDictionary(t => t.Id);
        var excludedTenderIds = biddedTenders.Select(t => t.Id).ToHashSet();

        var scoredDict = new Dictionary<int, List<double>>();
        var explanationDict = new Dictionary<int, List<string>>();

        if (userActivities.Any())
        {
            var activityProfile = BuildActivityProfile(userActivities);
            var searchQueries = GetRecentSearchQueries(userActivities);
            var viewedTenders = GetViewedTenders(userActivities);
            var activityVector = _builder.Build(activityProfile);
            var activityResults = _recommender.GetSimilar(activityVector, allVectors, topN * 3);

            foreach (var result in activityResults.Where(r => !excludedTenderIds.Contains(r.TenderId)))
            {
                AddScore(scoredDict, result.TenderId, result.Score);

                if (allTendersById.TryGetValue(result.TenderId, out var candidate))
                {
                    AddExplanation(
                        explanationDict,
                        result.TenderId,
                        BuildActivitySignals(candidate, searchQueries, viewedTenders, activityProfile));
                }
            }
        }

        foreach (var bidded in biddedTenders)
        {
            var sourceVector = _builder.Build(bidded);
            var partialResults = _recommender.GetSimilar(sourceVector, allVectors, topN * 3);

            foreach (var result in partialResults.Where(r => !excludedTenderIds.Contains(r.TenderId)))
            {
                AddScore(scoredDict, result.TenderId, result.Score);

                if (allTendersById.TryGetValue(result.TenderId, out var candidate))
                {
                    AddExplanation(
                        explanationDict,
                        result.TenderId,
                        BuildBidSignals(candidate, bidded));
                }
            }
        }



        var topIds = scoredDict
            .Where(kv => kv.Value.Average() >= MinSimilarityThreshold)
            .OrderByDescending(kv => kv.Value.Average())
            .Take(topN)
            .Select(kv => kv.Key)
            .ToHashSet();
      
        if (!topIds.Any())
            {
                return new RecommendationResultDTO
                {
                    Message = "No recommendations found that meet the similarity threshold."
                };
            }

        var tenderDetails = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Location)
            .Include(t => t.Images)
            .Where(t => topIds.Contains(t.Id))
            .ToListAsync();

        var recommendations = tenderDetails.Select(t => new TenderRecommendationDTO
        {
            TenderId = t.Id,
            Title = t.Title,
            Description = t.Description,
            MaxBudget = t.MaxBudget,
            Deadline = t.Deadline,
            Status = t.Status.ToString(),
            Category = t.Category?.Name,
            Country = t.Location?.Country,
            City = t.Location?.Name,
            LocationName = t.Location?.Name,
            Region = t.Location?.Region,
            ThumbnailUrl = t.Images.FirstOrDefault()?.ImageUrl,
            SimilarityScore = Math.Round(scoredDict[t.Id].Average(), 4),
            RecommendationSignals = explanationDict.TryGetValue(t.Id, out var signals)
                ? signals.Distinct().Take(4).ToList()
                : new List<string>(),
            RecommendationReason = BuildRecommendationReason(
                explanationDict.TryGetValue(t.Id, out var reasonSignals)
                    ? reasonSignals
                    : new List<string>())
        })
        .OrderByDescending(t => t.SimilarityScore)
        .ToList();

        return new RecommendationResultDTO { Recommendations = recommendations };
    }

    private Tender BuildActivityProfile(List<UserActivity> userActivities)
    {
        var activityProfile = new Tender
        {
            Id = 0,
            Title = "Fiktivni Target Profil",
            Status = TenderStatus.Open,
            Description = string.Join(" ", GetRecentSearchQueries(userActivities))
        };

        var viewedTenders = GetViewedTenders(userActivities);

        if (!viewedTenders.Any())
            return activityProfile;

        var dominantCategory = viewedTenders
            .GroupBy(t => t.CategoryId)
            .OrderByDescending(g => g.Count())
            .FirstOrDefault()?.FirstOrDefault();

        if (dominantCategory != null)
        {
            activityProfile.CategoryId = dominantCategory.CategoryId;
            activityProfile.Category = dominantCategory.Category;
        }

        var dominantLocation = viewedTenders
            .Where(t => t.Location != null)
            .GroupBy(t => t.LocationId)
            .OrderByDescending(g => g.Count())
            .FirstOrDefault()?.FirstOrDefault()?.Location;

        if (dominantLocation != null)
        {
            activityProfile.LocationId = dominantLocation.Id;
            activityProfile.Location = dominantLocation;
        }

        activityProfile.MaxBudget = viewedTenders.Average(t => t.MaxBudget);

        return activityProfile;
    }

    private List<string> BuildSimilaritySignals(Tender source, Tender candidate)
    {
        var signals = new List<string>();
        var sourceVector = _builder.Build(source);
        var candidateVector = _builder.Build(candidate);

        if (source.CategoryId == candidate.CategoryId)
            signals.Add($"Same category: {candidate.Category?.Name}");

        if (source.Location?.Country == candidate.Location?.Country && !string.IsNullOrWhiteSpace(candidate.Location?.Country))
            signals.Add($"Same country: {candidate.Location.Country}");

        if (source.LocationId == candidate.LocationId && !string.IsNullOrWhiteSpace(candidate.Location?.Name))
            signals.Add($"Same location: {candidate.Location.Name}");

        if (sourceVector.BudgetBucket == candidateVector.BudgetBucket)
            signals.Add("Similar budget range");

        var sharedKeywords = sourceVector.Keywords
            .Intersect(candidateVector.Keywords, StringComparer.OrdinalIgnoreCase)
            .Take(3)
            .ToList();

        if (sharedKeywords.Any())
            signals.Add($"Shared keywords: {string.Join(", ", sharedKeywords)}");

        return signals;
    }

    private static List<string> BuildActivitySignals(
        Tender candidate,
        List<string> searchQueries,
        List<Tender> viewedTenders,
        Tender activityProfile)
    {
        var signals = new List<string>();

        if (searchQueries.Any())
            signals.Add($"Matches recent searches: {string.Join(", ", searchQueries)}");

        if (activityProfile.CategoryId == candidate.CategoryId && !string.IsNullOrWhiteSpace(candidate.Category?.Name))
            signals.Add($"Similar to categories you viewed: {candidate.Category.Name}");

        if (activityProfile.LocationId == candidate.LocationId && !string.IsNullOrWhiteSpace(candidate.Location?.Name))
            signals.Add($"Similar to locations you viewed: {candidate.Location.Name}");

        if (viewedTenders.Any(t => t.Location?.Country == candidate.Location?.Country) &&
            !string.IsNullOrWhiteSpace(candidate.Location?.Country))
        {
            signals.Add($"In a country you viewed recently: {candidate.Location.Country}");
        }

        return signals;
    }

    private static List<string> BuildBidSignals(Tender candidate, Tender biddedTender)
    {
        var signals = new List<string> { $"Similar to a tender you bid on: {biddedTender.Title}" };

        if (biddedTender.CategoryId == candidate.CategoryId && !string.IsNullOrWhiteSpace(candidate.Category?.Name))
            signals.Add($"Same category as your bid history: {candidate.Category.Name}");

        if (biddedTender.Location?.Country == candidate.Location?.Country && !string.IsNullOrWhiteSpace(candidate.Location?.Country))
            signals.Add($"Same country as your bid history: {candidate.Location.Country}");

        if (TenderVectorBuilder.GetBudgetBucket(biddedTender.MaxBudget) == TenderVectorBuilder.GetBudgetBucket(candidate.MaxBudget))
            signals.Add("Similar budget range to tenders you bid on");

        return signals;
    }

    private static List<string> GetRecentSearchQueries(List<UserActivity> userActivities)
    {
        return userActivities
            .Where(a => a.ActivityType == ActivityRecommendType.TenderSearch && !string.IsNullOrEmpty(a.SearchQuery))
            .Select(a => a.SearchQuery!.Trim())
            .Where(q => !string.IsNullOrWhiteSpace(q))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(3)
            .ToList();
    }

    private static List<Tender> GetViewedTenders(List<UserActivity> userActivities)
    {
        return userActivities
            .Where(a => a.ActivityType == ActivityRecommendType.TenderViewed && a.Tender != null)
            .Select(a => a.Tender!)
            .ToList();
    }


    private static void AddScore(Dictionary<int, List<double>> scoredDict, int tenderId, double score)
    {
        if (!scoredDict.ContainsKey(tenderId))
            scoredDict[tenderId] = new List<double>();

        scoredDict[tenderId].Add(score);
    }

    private static void AddExplanation(Dictionary<int, List<string>> explanationDict, int tenderId, IEnumerable<string> signals)
    {
        if (!explanationDict.ContainsKey(tenderId))
            explanationDict[tenderId] = new List<string>();

        explanationDict[tenderId].AddRange(signals.Where(s => !string.IsNullOrWhiteSpace(s)));
    }

    private static string BuildRecommendationReason(IEnumerable<string> signals)
    {
        var topSignals = signals
            .Where(s => !string.IsNullOrWhiteSpace(s))
            .Distinct()
            .Take(2)
            .ToList();

        return topSignals.Any()
            ? $"Recommended because {string.Join(" and ", topSignals.Select(ToLowerFirst))}."
            : "Recommended because it matches your recent tender activity.";
    }

    private static string ToLowerFirst(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return value;

        return char.ToLowerInvariant(value[0]) + value[1..];
    }
}
