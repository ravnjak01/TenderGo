using Microsoft.AspNetCore.Mvc.RazorPages;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;

namespace TenderGo.Services.Interfaces
{
    public interface IReadService<T>
    {
        Task<PagedResult<T>> Get(PagedResult<T> pagedResult);
        Task<T> GetById(int id);
    }
}
