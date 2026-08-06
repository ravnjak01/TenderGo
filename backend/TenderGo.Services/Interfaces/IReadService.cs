using Microsoft.AspNetCore.Mvc.RazorPages;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Interfaces
{
    public interface IReadService<TModel, TSearch>
      where TModel : class
      where TSearch : PagedSearchRequest
    {
        Task<PagedResult<TModel>> Get(TSearch request);
        Task<TModel> GetById(int id);
    }
}
