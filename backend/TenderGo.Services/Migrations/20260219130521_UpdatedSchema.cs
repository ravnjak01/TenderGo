using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TenderGo.Services.Migrations
{
    /// <inheritdoc />
    public partial class UpdatedSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Ratings_AspNetUsers_RatedUserId",
                table: "Ratings");

            migrationBuilder.DropIndex(
                name: "IX_Ratings_TenderId",
                table: "Ratings");

            migrationBuilder.DropColumn(
                name: "Commit",
                table: "Ratings");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Tenders",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getdate())",
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldNullable: true,
                oldDefaultValueSql: "(getdate())");

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Tenders",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "WinningBidId",
                table: "Tenders",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Comment",
                table: "Ratings",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DeliveryNote",
                table: "Bids",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "TenderImages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ImageUrl = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsPrimary = table.Column<bool>(type: "bit", nullable: false),
                    TenderId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TenderImages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TenderImages_Tenders_TenderId",
                        column: x => x.TenderId,
                        principalTable: "Tenders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Tenders_WinningBidId",
                table: "Tenders",
                column: "WinningBidId");

            migrationBuilder.CreateIndex(
                name: "IX_Ratings_TenderId_RatedByUserId_RatedUserId",
                table: "Ratings",
                columns: new[] { "TenderId", "RatedByUserId", "RatedUserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TenderImages_TenderId",
                table: "TenderImages",
                column: "TenderId");

            migrationBuilder.AddForeignKey(
                name: "FK_Ratings_AspNetUsers_RatedUserId",
                table: "Ratings",
                column: "RatedUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Tenders_Bids_WinningBidId",
                table: "Tenders",
                column: "WinningBidId",
                principalTable: "Bids",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Ratings_AspNetUsers_RatedUserId",
                table: "Ratings");

            migrationBuilder.DropForeignKey(
                name: "FK_Tenders_Bids_WinningBidId",
                table: "Tenders");

            migrationBuilder.DropTable(
                name: "TenderImages");

            migrationBuilder.DropIndex(
                name: "IX_Tenders_WinningBidId",
                table: "Tenders");

            migrationBuilder.DropIndex(
                name: "IX_Ratings_TenderId_RatedByUserId_RatedUserId",
                table: "Ratings");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Tenders");

            migrationBuilder.DropColumn(
                name: "WinningBidId",
                table: "Tenders");

            migrationBuilder.DropColumn(
                name: "Comment",
                table: "Ratings");

            migrationBuilder.DropColumn(
                name: "DeliveryNote",
                table: "Bids");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Tenders",
                type: "datetime2",
                nullable: true,
                defaultValueSql: "(getdate())",
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "(getdate())");

            migrationBuilder.AddColumn<string>(
                name: "Commit",
                table: "Ratings",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Ratings_TenderId",
                table: "Ratings",
                column: "TenderId");

            migrationBuilder.AddForeignKey(
                name: "FK_Ratings_AspNetUsers_RatedUserId",
                table: "Ratings",
                column: "RatedUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
