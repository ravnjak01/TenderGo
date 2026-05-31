using TenderGo.Models.ENUMs;

namespace TenderGo.Recommender;


public class RecommenderService
{
    private const double WeightCategory = 0.40;
    private const double WeightCountry = 0.20;
    private const double WeightBudget = 0.15;
    private const double WeightKeywords = 0.15;
    private const double WeightLocation = 0.10;

    private readonly TenderVectorBuilder _builder = new();

    public List<ScoredTender> GetSimilar(
        TenderFeatureVector target,
        IEnumerable<TenderFeatureVector> candidates,
        int topN = 10)
    {
        return candidates
            .Where(c => c.TenderId != target.TenderId)
            .Where(c => c.Status == TenderStatus.Open)   
            .Select(c => new ScoredTender
            {
                TenderId = c.TenderId,
                Title = c.Title,
                Score = ComputeWeightedSimilarity(target, c)
            })
            .Where(s => s.Score > 0)                     
            .OrderByDescending(s => s.Score)
            .Take(topN)
            .ToList();
    }

 

    private double ComputeWeightedSimilarity(TenderFeatureVector a, TenderFeatureVector b)
    {
        double score = 0;

        score += WeightCategory * ExactMatchScore(a.Category, b.Category);
        score += WeightCountry * ExactMatchScore(a.Country, b.Country);
        score += WeightBudget * ExactMatchScore(a.BudgetBucket, b.BudgetBucket);
        score += WeightKeywords * KeywordSimilarity(a.Keywords, b.Keywords);
        score += WeightLocation * LocationSimilarity(a.City, b.City, a.Region ,b.Region,a.Country, b.Country);

        return Math.Round(score, 4);
    }


    private static double ExactMatchScore(string a, string b)
        => string.Equals(a, b, StringComparison.OrdinalIgnoreCase) ? 1.0 : 0.0;


    private static double KeywordSimilarity(List<string> aKeywords, List<string> bKeywords)
    {
        if (aKeywords.Count == 0 || bKeywords.Count == 0) return 0;

        var vecA = BuildFrequencyVector(aKeywords);
        var vecB = BuildFrequencyVector(bKeywords);

        var sharedKeys = vecA.Keys.Intersect(vecB.Keys);
        double dotProduct = sharedKeys.Sum(k => vecA[k] * vecB[k]);

        double magA = Math.Sqrt(vecA.Values.Sum(v => v * v));
        double magB = Math.Sqrt(vecB.Values.Sum(v => v * v));

        return (magA == 0 || magB == 0) ? 0 : dotProduct / (magA * magB);
    }

    private static double LocationSimilarity(
        string cityA, string cityB, string regionA, string regionB, string countryA, string countryB
        )
    {
        if (countryA != countryB) return 0.0;

        if (cityA == cityB && !string.IsNullOrEmpty(cityA)) return 1.0;

        if (regionA == regionB && !string.IsNullOrEmpty(regionA)) return 0.6;

        return 0.2;
    }


    private static Dictionary<string, double> BuildFrequencyVector(List<string> tokens)
    {
        var vector = new Dictionary<string, double>(StringComparer.OrdinalIgnoreCase);
        foreach (var token in tokens)
            vector[token] = vector.TryGetValue(token, out var count) ? count + 1 : 1;
        return vector;
    }
}


public class ScoredTender
{
    public int TenderId { get; set; }
    public string Title { get; set; } = null!;
    public double Score { get; set; }
}