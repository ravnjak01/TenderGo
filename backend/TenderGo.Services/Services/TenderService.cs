using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class TenderService:ITenderService
    {
        private readonly TenderGoContext _context;
        public TenderService(TenderGoContext context)
        {
            _context = context;
        }

        public IEnumerable<TenderDTO> GetAllTenders()
        {

        }
    }
}
