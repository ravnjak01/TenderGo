using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.Entities;

namespace TenderGo.Subscriber.Models
{
    public class NotificationDbContext : DbContext
    {
        public DbSet<Notification> Notifications { get; set; }

        public NotificationDbContext(DbContextOptions options) : base(options)
        {
        }
    }
}
