using TenderGo.Models.Entities;

namespace TenderGo.Recommender;

/// <summary>
/// Converts a Tender database entity into a TenderFeatureVector
/// that the recommender engine can compute similarity on.
/// </summary>
public class TenderVectorBuilder
{
    // Common English stop words to filter out from keywords
    private static readonly HashSet<string> StopWords = new(StringComparer.OrdinalIgnoreCase)
    {
        "the","a","an","of","and","or","for","in","to","is","with",
        "that","this","are","was","be","by","on","at","as","from",
        "will","have","has","had","not","but","its","our","your"
    };

    public TenderFeatureVector Build(Tender tender)
    {
        return new TenderFeatureVector
        {
            TenderId = tender.Id,
            Title = tender.Title,
            Status = tender.Status,
            Category = tender.Category?.Name ?? tender.CategoryId.ToString(),
            Country = (tender.Location?.Country ?? "").ToLower().Trim(),
            City = (tender.Location?.Name ?? "").ToLower().Trim(), 
            Region = (tender.Location?.Region ?? "").ToLower().Trim(),
            BudgetBucket = GetBudgetBucket(tender.MaxBudget),
            Keywords = ExtractKeywords(tender.Title, tender.Description),
        };
    }

    /// <summary>
    /// Groups budget into named ranges so nearby budgets score as similar
    /// instead of comparing raw decimal values directly.
    /// </summary>
    public static string GetBudgetBucket(decimal budget) => budget switch
    {
        < 500 =>"nano",
        < 1_000 => "micro",      // under 1k
        < 10_000 => "small",      // 1k – 10k
        < 50_000 => "medium",     // 10k – 50k
        < 200_000 => "large",      // 50k – 200k
        < 1_000_000 => "xlarge",     // 200k – 1M
        _ => "enterprise"  // 1M+
    };

    /// <summary>
    /// Tokenizes title + description into meaningful keywords,
    /// removing stop words and very short tokens.
    /// </summary>
    private List<string> ExtractKeywords(string title, string? description)
    {
        var raw = $"{title} {description ?? ""}";

        return raw
            .ToLower()
            .Split(new[] { ' ', ',', '.', '-', '/', '_', '(', ')', ':', ';', '\n', '\r' },
                   StringSplitOptions.RemoveEmptyEntries)
            .Where(w => w.Length > 2 && !StopWords.Contains(w))
            .Distinct()
            .ToList();
    }
}