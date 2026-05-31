using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TenderGo.Services.Migrations
{
    /// <inheritdoc />
    public partial class BidFluentApiUpdate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Bids_TenderId_SubmittedByUserId",
                table: "Bids");

            migrationBuilder.CreateIndex(
                name: "IX_Bids_TenderId_SubmittedByUserId",
                table: "Bids",
                columns: new[] { "TenderId", "SubmittedByUserId" },
                unique: true,
                filter: "[Status] IN ('Pending', 'Accepted')");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Bids_TenderId_SubmittedByUserId",
                table: "Bids");

            migrationBuilder.CreateIndex(
                name: "IX_Bids_TenderId_SubmittedByUserId",
                table: "Bids",
                columns: new[] { "TenderId", "SubmittedByUserId" },
                unique: true);
        }
    }
}
