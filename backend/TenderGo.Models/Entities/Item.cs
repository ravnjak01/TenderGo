using TenderGo.Models.ENUMs;

namespace TenderGo.Recommender;

public class TenderFeatureVector
{
    // Identity
    public int TenderId { get; set; }
    public string Title { get; set; } = null!;

    // === FEATURES USED FOR SIMILARITY ===

    // From Category (one-hot encoded as string key)
    public string Category { get; set; } = null!;       // e.g. "Construction"

    // From Location
    public string Country { get; set; } = null!;        // e.g. "BA"
    public string LocationName { get; set; } = null!;   // e.g. "Sarajevo"

    // From Budget — bucketed so nearby budgets score as similar
    public string BudgetBucket { get; set; } = null!;   // e.g. "10k-50k"

    // From Title + Description — extracted keywords
    public List<string> Keywords { get; set; } = new(); // e.g. ["road","construction","asphalt"]

    // Only open tenders should ever be recommended
    public TenderStatus Status { get; set; }
}