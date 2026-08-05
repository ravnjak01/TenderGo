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
    public interface IReadService<T, TSearch>
      where T : class
      where TSearch : PagedSearchRequest
    {
        Task<PagedResult<T>> Get(TSearch request);
        Task<T> GetById(int id);
    }
}
