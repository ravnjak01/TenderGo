namespace TenderGo.Models.Requests
{
    public class LocationSearchRequest : PagedSearchRequest
    {
        public bool? IsActive { get; set; }
    }
}
