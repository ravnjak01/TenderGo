    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Interfaces
    {
        public interface IBaseService<T>
        {
            Task<IEnumerable<T>> Get();
            Task<T?>GetById(int id);
             Task<T> Insert(TenderInsertRequest request);
              Task<T?> Update(int id, TenderUpdateRequest request);
                Task<bool> Delete(int id);
    }
    }
