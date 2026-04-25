using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.Entities;

namespace TenderGo.Models.DTOs
{
    public class UserPublicDTO
    {
        public string Id { get; set; }

        public string UserName { get; set; }

        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Location { get; set; }

        // Reputacija
        public double Rating { get; set; }
        public int ReviewCount { get; set; }

        // Aktivnost
        public int TenderCount { get; set; }
        public int BidsCount { get; set; }
    }
}