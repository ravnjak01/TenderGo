using TenderGo.Models.Entities;

namespace TenderGo.Recommender;

public class TenderVectorBuilder
{
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


    public static string GetBudgetBucket(decimal budget) => budget switch
    {
        < 500 =>"nano",
        < 1_000 => "micro",      
        < 10_000 => "small",      
        < 50_000 => "medium",     
        < 200_000 => "large",      
        < 1_000_000 => "xlarge",     
        _ => "enterprise"  
    };

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