using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using TenderGo.Models.Entities;

namespace TenderGo.Api.Database;

public partial class TenderGoContext : IdentityDbContext<ApplicationUser>
{
  
    public TenderGoContext(DbContextOptions<TenderGoContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Tender> Tenders { get; set; }
    public virtual DbSet<Bid>Bids { get; set; }
    public virtual DbSet<Category> Categories { get; set; }
    public virtual DbSet<Rating> Ratings { get; set; }
    public virtual DbSet<TenderImage> TenderImages { get; set; }
    public virtual DbSet<RefreshToken> RefreshTokens { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<Location> Locations { get; set; }


    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseSqlServer(@"Server=(localdb)\MSSQLLocalDB;Database=TenderGo;Trusted_Connection=True;TrustServerCertificate=True;");
        }
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)

    {

        base.OnModelCreating(modelBuilder);

        //tender
        modelBuilder.Entity<Tender>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Tenders__3214EC07AD891A81");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.MaxBudget).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Title).HasMaxLength(200);
            entity.Property(e => e.Status).HasConversion<string>();

            entity.Property(e=>e.Status).HasConversion<string>();

            entity.HasOne(t=>t.WinningBid)
                .WithMany()
                .HasForeignKey(t => t.WinningBidId)
                .OnDelete(DeleteBehavior.Restrict);



            entity.HasOne(t => t.CreatedByUser)
                .WithMany(t=>t.CreatedTenders)
                .HasForeignKey(t => t.CreatedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(t => t.Category)
                  .WithMany()
                  .HasForeignKey(t => t.CategoryId)
                  .OnDelete(DeleteBehavior.Restrict);

        });
        modelBuilder.Entity<Tender>().HasQueryFilter(t => !t.IsDeleted);

        modelBuilder.Entity<Tender>().Navigation(b => b.CreatedByUser).AutoInclude();//da se uvijek ucitava korisnik koji je kreirao tender

        // Sakrij ponude čiji je tender obrisan
        modelBuilder.Entity<Bid>().HasQueryFilter(b => !b.Tender.IsDeleted);

        // Sakrij ocjene čiji je tender obrisan
        modelBuilder.Entity<Rating>().HasQueryFilter(r => !r.Tender.IsDeleted);

        // Sakrij slike čiji je tender obrisan
        modelBuilder.Entity<TenderImage>().HasQueryFilter(ti => !ti.Tender.IsDeleted);

        modelBuilder.Entity<Tender>()
        .HasOne(t => t.Location)
        .WithMany() 
        .HasForeignKey(t => t.LocationId)
        .OnDelete(DeleteBehavior.Restrict);


//zadnje dodao ovo za adresu
        modelBuilder.Entity<ApplicationUser>()
         .OwnsOne(u => u.Address);

        //rating
        modelBuilder.Entity<Rating>(entity =>
        {

            entity.HasOne(d => d.RatedUser) 
                        .WithMany(p => p.RatingsReceived)
                    .HasForeignKey(d => d.RatedUserId)
                     .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(d => d.RatedByUser)
                    .WithMany(p => p.RatingsGiven)
                    .HasForeignKey(d => d.RatedByUserId)
                    .OnDelete(DeleteBehavior.Restrict);


            modelBuilder.Entity<Rating>()
                .HasIndex(r => new { r.TenderId, r.RatedByUserId, r.RatedUserId })
                 .IsUnique();
        
        });
        OnModelCreatingPartial(modelBuilder);


        //bid
        modelBuilder.Entity<Bid>().Navigation(b => b.SubmittedByUser).AutoInclude();//da se uvijek ucitava korisnik koji je poslao bid
        modelBuilder.Entity<Bid>(entity =>
        {
            // Primarni ključ
            entity.HasKey(e => e.Id);

            // Konfiguracija veze 1:N (Jedan Tender -> Više Bids)
            entity.HasOne(b => b.Tender)           // Bid ima jedan Tender
                  .WithMany(t => t.Bids)           // Tender ima mnogo Bids
                  .HasForeignKey(b => b.TenderId)  // Strani ključ je TenderId
                  .OnDelete(DeleteBehavior.Cascade); 

            entity.Property(b => b.OfferedPrice).HasPrecision(18, 2);

            // 1 korisnik može poslati samo jedan bid po tenderu
            entity.HasIndex(b => new { b.TenderId, b.SubmittedByUserId })
                 .IsUnique();

            entity.HasOne(b => b.SubmittedByUser)
            .WithMany() 
            .HasForeignKey(b => b.SubmittedByUserId)
            .OnDelete(DeleteBehavior.Restrict);
        });


        //tender images
        modelBuilder.Entity<TenderImage>(entity =>
        {
            entity.HasOne(ti => ti.Tender)
                  .WithMany(t => t.Images)
                  .HasForeignKey(ti => ti.TenderId)
                  .OnDelete(DeleteBehavior.Cascade); 
        });

        modelBuilder.Entity<Notification>(entity =>
        {
                        entity.HasOne(n => n.User) 
                     .WithMany()
                     .HasForeignKey(n => n.UserId)
                     .OnDelete(DeleteBehavior.Cascade);
        });


        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasOne(rt => rt.User)
                  .WithMany()
                  .HasForeignKey(rt => rt.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Location>(entity =>
        {
            entity.ToTable("Locations");

            entity.HasKey(l => l.Id);

            entity.Property(l => l.Name)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(l => l.Country)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(l => l.Region)
                .HasMaxLength(100);
        });

    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
