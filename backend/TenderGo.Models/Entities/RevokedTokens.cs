using System.ComponentModel.DataAnnotations;

public class RevokedToken
{
    public int Id { get; set; }

    [Required]
    public string Jti { get; set; } = string.Empty;

    [Required]
    public string UserId { get; set; } = string.Empty;

    public DateTime RevokedAt { get; set; } = DateTime.UtcNow;

    public DateTime ExpiresAt { get; set; }
}