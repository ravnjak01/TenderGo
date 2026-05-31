using System;

namespace TenderGo.Models.Entities;

public class UserActivity
{
    public int Id { get; set; }
    
    // Poveznica sa ulogovanim korisnikom (npr. Identity User string ili int ID)
    public string UserId { get; set; } = null!;
    
    // Tip akcije: "Search" ili "View"
    public string ActivityType { get; set; } = null!;
    
    // Ako je akcija "View", ovdje spašavamo ID tendera koji je gledao
    public int? TenderId { get; set; }
    
    // Ako je akcija "Search", ovdje spašavamo tekst koji je kucao
    public string? SearchQuery { get; set; }
    
    // Vrijeme kada se akcija desila
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    // Navigacijska svojstva (opcionalno, ako imaš Tender entitet)
    public Tender? Tender { get; set; }
}