namespace TenderGo.Models.Requests
{
    public class AdminUserSearchRequest : PagedSearchRequest
    {
        public string? SearchTerm { get; set; }
    }
}
