using TenderGo.Models.ENUMs;

namespace TenderGo.Recommender;

/// <summary>
/// Core content-based recommender engine.
/// Computes weighted cosine similarity between TenderFeatureVectors
/// and returns the top-N most similar tenders.
/// </summary>
public class RecommenderService
{
    // ---------------------------------------------------------------
    // Feature weights — must sum to 1.0
    // Tweak these based on what your users care about most.
    // ---------------------------------------------------------------
    private const double WeightCategory = 0.40;
    private const double WeightCountry = 0.20;
    private const double WeightBudget = 0.15;
    private const double WeightKeywords = 0.15;
    private const double WeightLocation = 0.10;

    private readonly TenderVectorBuilder _builder = new();

    // ---------------------------------------------------------------
    // Public API
    // ---------------------------------------------------------------

    /// <summary>
    /// Given a target tender ID and all available tenders,
    /// returns the top-N most similar OPEN tenders.
    /// </summary>
    public List<ScoredTender> GetSimilar(
        TenderFeatureVector target,
        IEnumerable<TenderFeatureVector> candidates,
        int topN = 10)
    {
        return candidates
            .Where(c => c.TenderId != target.TenderId)
            .Where(c => c.Status == TenderStatus.Open)   // only recommend open tenders
            .Select(c => new ScoredTender
            {
                TenderId = c.TenderId,
                Title = c.Title,
                Score = ComputeWeightedSimilarity(target, c)
            })
            .Where(s => s.Score > 0)                     // skip completely unrelated
            .OrderByDescending(s => s.Score)
            .Take(topN)
            .ToList();
    }

    // ---------------------------------------------------------------
    // Weighted similarity — combines all feature scores
    // ---------------------------------------------------------------

    private double ComputeWeightedSimilarity(TenderFeatureVector a, TenderFeatureVector b)
    {
        double score = 0;

        score += WeightCategory * ExactMatchScore(a.Category, b.Category);
        score += WeightCountry * ExactMatchScore(a.Country, b.Country);
        score += WeightBudget * ExactMatchScore(a.BudgetBucket, b.BudgetBucket);
        score += WeightKeywords * KeywordSimilarity(a.Keywords, b.Keywords);
        score += WeightLocation * LocationSimilarity(a.LocationName, b.LocationName, a.Country, b.Country);

        return Math.Round(score, 4);
    }

    // ---------------------------------------------------------------
    // Individual feature scorers
    // ---------------------------------------------------------------

    /// <summary>
    /// Returns 1.0 if both strings match exactly, 0.0 otherwise.
    /// Used for categorical features like Category, Country, BudgetBucket.
    /// </summary>
    private static double ExactMatchScore(string a, string b)
        => string.Equals(a, b, StringComparison.OrdinalIgnoreCase) ? 1.0 : 0.0;

    /// <summary>
    /// Cosine similarity over keyword sets.
    /// Treats each unique keyword as a dimension; value = occurrence count.
    /// </summary>
    private static double KeywordSimilarity(List<string> aKeywords, List<string> bKeywords)
    {
        if (aKeywords.Count == 0 || bKeywords.Count == 0) return 0;

        // Build frequency vectors
        var vecA = BuildFrequencyVector(aKeywords);
        var vecB = BuildFrequencyVector(bKeywords);

        // Dot product of shared dimensions
        var sharedKeys = vecA.Keys.Intersect(vecB.Keys);
        double dotProduct = sharedKeys.Sum(k => vecA[k] * vecB[k]);

        // Magnitudes
        double magA = Math.Sqrt(vecA.Values.Sum(v => v * v));
        double magB = Math.Sqrt(vecB.Values.Sum(v => v * v));

        return (magA == 0 || magB == 0) ? 0 : dotProduct / (magA * magB);
    }

    /// <summary>
    /// Gives full score if same city, partial score if same country only.
    /// </summary>
    private static double LocationSimilarity(
        string locA, string locB,
        string countryA, string countryB)
    {
        if (string.Equals(locA, locB, StringComparison.OrdinalIgnoreCase)) return 1.0;
        if (string.Equals(countryA, countryB, StringComparison.OrdinalIgnoreCase)) return 0.4;
        return 0.0;
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    private static Dictionary<string, double> BuildFrequencyVector(List<string> tokens)
    {
        var vector = new Dictionary<string, double>(StringComparer.OrdinalIgnoreCase);
        foreach (var token in tokens)
            vector[token] = vector.TryGetValue(token, out var count) ? count + 1 : 1;
        return vector;
    }
}

/// <summary>
/// A tender with its computed similarity score.
/// </summary>
public class ScoredTender
{
    public int TenderId { get; set; }
    public string Title { get; set; } = null!;
    public double Score { get; set; }
}