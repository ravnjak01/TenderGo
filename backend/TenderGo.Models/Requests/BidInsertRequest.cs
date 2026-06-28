using System.ComponentModel.DataAnnotations;

public class BidInsertRequest
{
    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Price { get; set; }

    [Required]
    public int TenderId { get; set; }

    [StringLength(500)]
    public string? Note { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;

    [Required]
    [Range(1, int.MaxValue)]
    public int DeliveryDays { get; set; }
}