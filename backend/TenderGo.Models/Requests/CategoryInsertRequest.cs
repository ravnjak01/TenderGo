using System.ComponentModel.DataAnnotations;

public class CategoryInsertRequest
{
    [Required(ErrorMessage = "Naziv kategorije je obavezan.")]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Opis kategorije je obavezan.")]
    [StringLength(500)]
    public string Description { get; set; } = string.Empty;
}