using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

public interface ICategoryService : IReadService<CategoryDTO>, IWriteService<CategoryDTO, CategoryDTO, CategoryUpdateRequest>
{
    Task<PagedResult<CategoryDTO>> SearchAsync(CategorySearchRequest request);
    Task<CategoryDTO> Activate(int id);
    Task<List<CategoryStatsDTO>> GetCategoryStatisticsAsync();
}
