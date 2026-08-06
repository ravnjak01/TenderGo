using Microsoft.AspNetCore.Mvc;
using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Interfaces
    {
    public interface IBaseService<TModel, TSearch, TInsert, TUpdate>
      : IReadService<TModel, TSearch>, IWriteService<TModel, TInsert, TUpdate>
      where TModel : class
      where TSearch:PagedSearchRequest
    {
    }
}
