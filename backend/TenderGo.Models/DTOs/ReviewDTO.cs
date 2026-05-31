public class ReviewDTO
{
    public int Id { get; set; }
    public int Rating { get; set; }
    public string Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    
    public string ReviewerName { get; set; } 

    public int TenderId { get; set; }
    public string TenderTitle { get; set; } 
}