using TenderGo.Models.Entities;

public class PasswordResetCode
{
    public int Id { get; set; }
    
    public string UserId { get; set; }
    public virtual ApplicationUser User { get; set; } 
    //zadnje promjenio reset lozinke metodu,da se salje code
    public string Code { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiryTime { get; set; }
    
    public bool IsUsed { get; set; }
    public DateTime? UsedAt { get; set; } 
    
    public int Attempts { get; set; } = 0; 
    public bool IsInvalidated { get; set; } 

    public string Salt {get; set;}
}