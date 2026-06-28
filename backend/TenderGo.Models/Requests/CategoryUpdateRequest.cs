using System.ComponentModel.DataAnnotations;

public class CategoryUpdateRequest
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;
}