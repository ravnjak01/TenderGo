namespace TenderGo.Models.Requests
{
    public class LocationFilterRequest
    {
        public string? Country { get; set; }
        public string? Region { get; set; }

        public bool IncludeInactive { get; set; } = false;
    }
}