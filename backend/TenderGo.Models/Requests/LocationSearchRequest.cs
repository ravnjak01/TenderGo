namespace TenderGo.Models.Requests
{
    public class LocationSearchRequest : PagedSearchRequest
    {
        public string? SearchTerm { get; set; }
        public bool? IsActive { get; set; }
        public string? Country { get; set; }
    }
}
