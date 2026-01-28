using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using TenderGo.Models.Entities;

namespace TenderGo.Api.Database;

public partial class TenderGoContext : IdentityDbContext<ApplicationUser>
{
    public TenderGoContext()
    {
    }

    public TenderGoContext(DbContextOptions<TenderGoContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Tender> Tenders { get; set; }
    public virtual DbSet<Rating> Ratings { get; set; }

    public virtual DbSet<TenderApplication> TenderApplications { get; set; }
    public virtual DbSet<Category> Categories { get; set; }
    public virtual DbSet<ApplicationUser> Users { get; set; }
    public virtual DbSet<Bid>Bids { get; set; }




    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {

    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)

    {

        base.OnModelCreating(modelBuilder);
        modelBuilder.Entity<Tender>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Tenders__3214EC07AD891A81");

            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.MaxBudget).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Title).HasMaxLength(200);
            entity.Property(e => e.Status).HasConversion<string>();
        });

        modelBuilder.Entity<Rating>(entity =>
        {

            entity.HasOne(d => d.RatedByUser)
                .WithMany(p => p.Ratings)
                .HasForeignKey(d => d.RatedUserId)
                .OnDelete(DeleteBehavior.Restrict);


            entity.HasOne(d=>d.RatedByUser)
                .WithMany()
                .HasForeignKey(d => d.RatedByUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });
        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
