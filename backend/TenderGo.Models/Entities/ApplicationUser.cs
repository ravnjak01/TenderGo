using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TenderGo.Models.Entities
{
    public class ApplicationUser:IdentityUser
    {
        public string FirstName { get; set; }=string.Empty;
        public string LastName { get; set; } = string.Empty;

        public string? ProfileImageUrl { get; set; }

        public Address Address { get; set; } 
        public DateTime CreatedAt { get; set; }
        public string? CreatedBy { get; set; }

        public DateTime? UpdatedAt { get; set; }
        public DateTime? UpdatedBy { get; set; }

        public bool? IsDeleted { get; set; }=false;

        public virtual ICollection<Tender> CreatedTenders { get; set; } = new List<Tender>();


        public virtual ICollection<Rating> RatingsReceived { get; set; } = new List<Rating>();
        public virtual ICollection<Rating> RatingsGiven { get; set; } = new List<Rating>();

        public double AverageRating { get; set; } = 0;
        public int RatingCount { get; set; } = 0;

        public bool IsBanned { get; set; } = false;
        public string? BanReason { get; set; }
        public DateTime? BannedAt { get; set; }

        public int NameChangeCount { get; set; } = 0;
    }
}
