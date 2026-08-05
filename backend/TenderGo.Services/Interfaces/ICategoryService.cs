using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

public interface ICategoryService : IReadService<CategoryDTO,CategorySearchRequest>, IWriteService<CategoryDTO, CategoryInsertRequest, CategoryUpdateRequest>
{
    Task<CategoryDTO> Activate(int id);
    Task<CategoryDTO> Deactivate(int id);
    Task<List<CategoryStatsDTO>> GetCategoryStatisticsAsync();
}
