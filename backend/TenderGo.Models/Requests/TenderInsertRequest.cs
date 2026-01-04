using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Requests
{
    public class TenderInsertRequest
    {
        public string Title { get; set; }
        public decimal MaxBudget { get; set; }
    }
}
