using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.ENUMs
{
    public enum ApplicationStatus
    {
       Pending = 1,
        Accepted = 2,
        Rejected = 3,
        Withdrawn = 4,   
        Cancelled = 5
    }
}

public enum TenderStatus
{
    Open = 1,
    Closed = 2,
    Awarded = 3,
    Cancelled = 4
}
