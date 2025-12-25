using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace TenderGo.Api.Database;

public partial class TenderGoContext : DbContext
{
    public TenderGoContext()
    {
    }

    public TenderGoContext(DbContextOptions<TenderGoContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Tender> Tenders { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Data Source=(localdb)\\MSSQLLocalDB;Initial Catalog=TenderGo;TrustServerCertificate=true;Trusted_Connection=true");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Tender>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Tenders__3214EC07AD891A81");

            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.MaxBudget).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Title).HasMaxLength(200);
            entity.Property(e => e.UserId).HasMaxLength(450);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
