using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;

namespace TenderGo.Services.Interfaces
{
    public interface IDataSeeder
    {
        int Order { get; }
        Task SeedAsync(TenderGoContext context, IServiceProvider serviceProvider);
    }
}
