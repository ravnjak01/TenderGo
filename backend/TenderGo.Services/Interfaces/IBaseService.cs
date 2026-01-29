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
        public interface IBaseService<T,TDb,TInsert,TUpdate>
        {
        Task<IEnumerable<T>> Get();
        Task<T> GetById(int id);              
        Task<T> Insert(TInsert request);
        Task Update(int id, TUpdate request); 
        Task Delete(int id);
     


    }
}
