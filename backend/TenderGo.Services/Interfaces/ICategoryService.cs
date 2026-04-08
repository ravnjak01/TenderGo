using TenderGo.Models.DTOs;
using TenderGo.Services.Interfaces;

public interface ICategoryService : IReadService<CategoryDTO>, IWriteService<CategoryDTO, CategoryDTO, CategoryDTO>
{
}
