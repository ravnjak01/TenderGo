namespace TenderGo.Models.Requests
{
    public class CategorySearchRequest : PagedSearchRequest
    {
        public string? SearchTerm { get; set; }
    }
}
