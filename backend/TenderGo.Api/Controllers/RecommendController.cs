using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using TenderGo.Api.Database;
using TenderGo.Data;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Recommender;

namespace TenderGo.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]                         
public class RecommendController : ControllerBase
{
    private readonly TenderGoContext _db;
    private readonly RecommenderService _recommender;
    private readonly TenderVectorBuilder _builder;

    public RecommendController(
        TenderGoContext db,
        RecommenderService recommender,
        TenderVectorBuilder builder)
    {
        _db = db;
        _recommender = recommender;
        _builder = builder;
    }

    [HttpGet("similar/{tenderId:int}")]
    public async Task<IActionResult> GetSimilar(int tenderId, [FromQuery] int topN = 10)
    {
        var allTenders = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Location)
            .Where(t => t.Id!=tenderId && t.Status==TenderStatus.Open)                   
            .ToListAsync();

        var target = allTenders.FirstOrDefault(t => t.Id == tenderId);
        if (target is null)
            return NotFound(new { message = $"Tender {tenderId} not found." });

        var targetVector = _builder.Build(target);
        var candidateVectors = allTenders.Select(t => _builder.Build(t)).ToList();

        var results = _recommender.GetSimilar(targetVector, candidateVectors, topN);

        if (!results.Any())
            return Ok(new { message = "No similar tenders found.", recommendations = results });

        var resultIds = results.Select(r => r.TenderId).ToHashSet();
        var tenderDetails = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Location)
            .Include(t => t.Images)
            .Where(t => resultIds.Contains(t.Id))
            .ToListAsync();

        var response = results
            .Join(tenderDetails,
                  scored => scored.TenderId,
                  tender => tender.Id,
                  (scored, tender) =>
                  {
                      var signals = BuildSimilaritySignals(target, tender);

                      return new TenderRecommendationDto
                      {
                          TenderId = tender.Id,
                          Title = tender.Title,
                          Description = tender.Description,
                          MaxBudget = tender.MaxBudget,
                          Deadline = tender.Deadline,
                          Status = tender.Status.ToString(),
                          Category = tender.Category?.Name,
                          Country = tender.Location.Country,
                          LocationName = tender.Location.Name,
                          Region = tender.Location.Region,
                          ThumbnailUrl = tender.Images.FirstOrDefault()?.ImageUrl,
                          SimilarityScore = scored.Score,
                          RecommendationSignals = signals,
                          RecommendationReason = BuildRecommendationReason(signals)
                      };
                  })
            .ToList();

        return Ok(response);
    }

    // ------------------------------------------------------------------
    // GET api/recommend/for-user?topN=10
    // Returns recommendations based on the current user's bid history.
    // Finds tenders they bid on → builds a profile → recommends similar open ones.
    // ------------------------------------------------------------------
   [HttpGet("for-user")]
public async Task<IActionResult> GetForCurrentUser([FromQuery] int topN = 10)
{
    var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
    if (userId is null) return Unauthorized();

    // =================================================================
    // KORAK 1: Povlačenje istorije ponuda (Bids) i aktivnosti (UserActivities)
    // =================================================================
    var biddedTenders = await _db.Tenders
        .Include(t => t.Category)
        .Include(t => t.Bids)
        .Where(t => t.Bids.Any(b => b.SubmittedByUserId == userId) && !t.IsDeleted)
        .ToListAsync();

    var userActivities = await _db.UserActivities
        .Include(a => a.Tender!).ThenInclude(t => t.Category)
        .Include(a => a.Tender!).ThenInclude(t => t.Location)
        .Where(a => a.UserId == userId)
        .OrderByDescending(a => a.Timestamp)
        .Take(20) // Uzimamo zadnjih 20 akcija radi svježine
        .ToListAsync();

    // Ako nema ni ponuda ni aktivnosti, vrati poruku za prazno stanje
    if (!biddedTenders.Any() && !userActivities.Any())
    {
        return Ok(new { message = "No history found. Start searching or viewing tenders!", recommendations = Array.Empty<object>() });
    }

    // Učitaj sve aktivne tendere za poređenje (kandidate)
    var allTenders = await _db.Tenders
        .Include(t => t.Category)
        .Include(t => t.Location)
        .Include(t => t.Images)
        .Where(t => !t.IsDeleted && t.Status == TenderStatus.Open)
        .ToListAsync();

    var allVectors = allTenders.Select(t => _builder.Build(t)).ToList();
    var allTendersById = allTenders.ToDictionary(t => t.Id);
    var excludedTenderIds = biddedTenders.Select(t => t.Id).ToHashSet();

    // Rječnik za prikupljanje rezultata poređenja
    var scoredDict = new Dictionary<int, List<double>>();
    var explanationDict = new Dictionary<int, List<string>>();

    // =================================================================
    // KORAK 2: KREIRANJE FIKTIVNOG TENDERA IZ USER ACTIVITIES (Spajanje!)
    // =================================================================
    if (userActivities.Any())
    {
        var fiktivniTender = new Tender
        {
            Id = 0, // Označava da je fiktivni objekt u memoriji
            Title = "Fiktivni Target Profil",
            Status = TenderStatus.Open
        };

        // Spajamo sve tekstualne pretrage korisnika u opis fiktivnog tendera
        var searchQueries = userActivities
            .Where(a => a.ActivityType == "Search" && !string.IsNullOrEmpty(a.SearchQuery))
            .Select(a => a.SearchQuery!.Trim())
            .Where(q => !string.IsNullOrWhiteSpace(q))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(3)
            .ToList();
        fiktivniTender.Description = string.Join(" ", searchQueries);

        // Izvlačimo tendere koje je korisnik samo kliknuo/gledao
        var viewedTenders = userActivities
            .Where(a => a.ActivityType == "View" && a.Tender != null)
            .Select(a => a.Tender!)
            .ToList();

        // Određujemo najčešću kategoriju i lokaciju iz klikova
        if (viewedTenders.Any())
        {
            var dominantCategory = viewedTenders
                .GroupBy(t => t.CategoryId)
                .OrderByDescending(g => g.Count())
                .FirstOrDefault()?.FirstOrDefault();

            if (dominantCategory != null)
            {
                fiktivniTender.CategoryId = dominantCategory.CategoryId;
                fiktivniTender.Category = dominantCategory.Category;
            }

            var dominantLocation = viewedTenders
                .Where(t => t.Location != null)
                .GroupBy(t => t.LocationId)
                .OrderByDescending(g => g.Count())
                .FirstOrDefault()?.FirstOrDefault()?.Location;

            if (dominantLocation != null)
            {
                fiktivniTender.LocationId = dominantLocation.Id;
                fiktivniTender.Location = dominantLocation;
            }

            fiktivniTender.MaxBudget = viewedTenders.Average(t => t.MaxBudget);
        }

        // -------------------------------------------------------------
        // KORAK 3: PROSLJEĐIVANJE FIKTIVNOG TENDERA U VECTOR BUILDER
        // -------------------------------------------------------------
        var fiktivniVector = _builder.Build(fiktivniTender);

        // Poredimo naš fiktivni profil sa svim otvorenim tenderima
        var fiktivniResults = _recommender.GetSimilar(fiktivniVector, allVectors, topN * 3);

        foreach (var r in fiktivniResults.Where(r => !excludedTenderIds.Contains(r.TenderId)))
        {
            if (!scoredDict.ContainsKey(r.TenderId))
                scoredDict[r.TenderId] = new List<double>();
            
            // Dajemo malo veći značaj (težinu) eksplicitnim akcijama ili ih direktno sabiramo
            scoredDict[r.TenderId].Add(r.Score);

            if (allTendersById.TryGetValue(r.TenderId, out var candidate))
            {
                AddExplanation(
                    explanationDict,
                    r.TenderId,
                    BuildActivitySignals(candidate, searchQueries, viewedTenders, fiktivniTender));
            }
        }
    }

    // =================================================================
    // KORAK 4: DODAVANJE ISTORIJE PONUDA (Tvoj postojeći algoritam)
    // =================================================================
    foreach (var bidded in biddedTenders)
    {
        var sourceVector = _builder.Build(bidded);
        var partialResults = _recommender.GetSimilar(sourceVector, allVectors, topN * 3);

        foreach (var r in partialResults.Where(r => !excludedTenderIds.Contains(r.TenderId)))
        {
            if (!scoredDict.ContainsKey(r.TenderId))
                scoredDict[r.TenderId] = new List<double>();
            
            scoredDict[r.TenderId].Add(r.Score);

            if (allTendersById.TryGetValue(r.TenderId, out var candidate))
            {
                AddExplanation(
                    explanationDict,
                    r.TenderId,
                    BuildBidSignals(candidate, bidded));
            }
        }
    }

    // =================================================================
    // KORAK 5: AGREGACIJA SKOROVA I FORMIRANJE ODGOVORA
    // =================================================================
    var topIds = scoredDict
        .OrderByDescending(kv => kv.Value.Average())
        .Take(topN)
        .Select(kv => kv.Key)
        .ToHashSet();

    var tenderDetails = await _db.Tenders
        .Include(t => t.Category)
        .Include(t => t.Location)
        .Include(t => t.Images)
        .Where(t => topIds.Contains(t.Id))
        .ToListAsync();

    var response = tenderDetails.Select(t => new TenderRecommendationDto
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

    return Ok(response);
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

public class TenderRecommendationDto
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
