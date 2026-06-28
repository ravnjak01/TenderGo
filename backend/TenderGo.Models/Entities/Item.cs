using TenderGo.Models.ENUMs;

namespace TenderGo.Recommender;

public class TenderFeatureVector
{
   
    public int TenderId { get; set; }
    public string Title { get; set; } = null!;


    public string Category { get; set; } = null!;       

    public string Country { get; set; } = null!;        
    public string City { get; set; } = null!;   
    public string Region { get; set; }

    public string BudgetBucket { get; set; } = null!;   

    public List<string> Keywords { get; set; } = new(); 

    public TenderStatus Status { get; set; }
}