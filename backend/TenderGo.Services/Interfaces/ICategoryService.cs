using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

public interface ICategoryService : IReadService<CategoryDTO>, IWriteService<CategoryDTO, CategoryDTO, CategoryUpdateRequest>
{
    Task<CategoryDTO> Activate(int id);
}
