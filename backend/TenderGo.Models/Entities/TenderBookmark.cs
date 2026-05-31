using TenderGo.Models.Entities;

public class TenderBookmark
{
    public string UserId { get; set; }
    public ApplicationUser User { get; set; } // Tvoja klasa za korisnika

    public int TenderId { get; set; }
    public Tender Tender { get; set; }

    public DateTime BookmarkedAt { get; set; } = DateTime.UtcNow;
}