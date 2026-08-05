using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Services.Interfaces
{
    public interface IWriteService<T,TInsert, TUpdate> 
           where T : class
    {
        Task<T> Insert(TInsert request);
        Task<T> Update(int id, TUpdate request);
        Task<string> Delete(int id);
    }

}
