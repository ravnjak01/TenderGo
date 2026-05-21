using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using TenderGo.Api.Database;
using TenderGo.Data;
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

    // ------------------------------------------------------------------
    // GET api/recommend/similar/{tenderId}?topN=10
    // Returns tenders similar to a given tender.
    // ------------------------------------------------------------------
    [HttpGet("similar/{tenderId:int}")]
    public async Task<IActionResult> GetSimilar(int tenderId, [FromQuery] int topN = 10)
    {
        // 1. Load all open tenders with their Category (needed for name)
        var allTenders = await _db.Tenders
            .Include(t => t.Category)
            .Where(t => !t.IsDeleted)                   // from BaseEntity
            .ToListAsync();

        // 2. Find the target tender
        var target = allTenders.FirstOrDefault(t => t.Id == tenderId);
        if (target is null)
            return NotFound(new { message = $"Tender {tenderId} not found." });

        // 3. Build feature vectors
        var targetVector = _builder.Build(target);
        var candidateVectors = allTenders.Select(t => _builder.Build(t)).ToList();

        // 4. Run recommender
        var results = _recommender.GetSimilar(targetVector, candidateVectors, topN);

        if (!results.Any())
            return Ok(new { message = "No similar tenders found.", recommendations = results });

        // 5. Fetch full tender data for the result IDs
        var resultIds = results.Select(r => r.TenderId).ToHashSet();
        var tenderDetails = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Images)
            .Where(t => resultIds.Contains(t.Id))
            .ToListAsync();

        // 6. Merge score into response DTO, preserving ranking order
        var response = results
            .Join(tenderDetails,
                  scored => scored.TenderId,
                  tender => tender.Id,
                  (scored, tender) => new TenderRecommendationDto
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
                      SimilarityScore = scored.Score
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

        // 1. Load tenders this user has bid on
        var biddedTenders = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Bids)
            .Where(t => t.Bids.Any(b => b.SubmittedByUserId == userId) && !t.IsDeleted)
            .ToListAsync();

        if (!biddedTenders.Any())
            return Ok(new { message = "No bid history found. Browse some tenders first!", recommendations = Array.Empty<object>() });

        // 2. Build a "user profile" by aggregating all bidded tender vectors
        //    then find tenders most similar to their interests
        var allTenders = await _db.Tenders
            .Include(t => t.Category)
            .Include(t => t.Images)
            .Where(t => !t.IsDeleted)
            .ToListAsync();

        var allVectors = allTenders.Select(t => _builder.Build(t)).ToList();
        var biddedIds = biddedTenders.Select(t => t.Id).ToHashSet();

        // Score every open tender against ALL bidded tenders, average the scores
        var scoredDict = new Dictionary<int, List<double>>();

        foreach (var bidded in biddedTenders)
        {
            var sourceVector = _builder.Build(bidded);
            var partialResults = _recommender.GetSimilar(sourceVector, allVectors, topN * 3);

            foreach (var r in partialResults.Where(r => !biddedIds.Contains(r.TenderId)))
            {
                if (!scoredDict.ContainsKey(r.TenderId))
                    scoredDict[r.TenderId] = new List<double>();
                scoredDict[r.TenderId].Add(r.Score);
            }
        }

        // Take top-N by average score
        var topIds = scoredDict
            .OrderByDescending(kv => kv.Value.Average())
            .Take(topN)
            .Select(kv => kv.Key)
            .ToHashSet();

        var tenderDetails = await _db.Tenders
            .Include(t => t.Category)
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
            Country = t.Location.Country,
            City=t.Location.Name,
            Region = t.Location.Region,
            ThumbnailUrl = t.Images.FirstOrDefault()?.ImageUrl,
            SimilarityScore = scoredDict[t.Id].Average()
        })
        .OrderByDescending(t => t.SimilarityScore)
        .ToList();

        return Ok(response);
    }
}

// ------------------------------------------------------------------
// Response DTO — only expose what the Flutter app needs
// ------------------------------------------------------------------
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
}