using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TenderGo.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddTenderCancellationAudit : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CancellationReason",
                table: "Tenders",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CancelledAt",
                table: "Tenders",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CancelledByUserId",
                table: "Tenders",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Tenders_CancelledByUserId",
                table: "Tenders",
                column: "CancelledByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Tenders_AspNetUsers_CancelledByUserId",
                table: "Tenders",
                column: "CancelledByUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Tenders_AspNetUsers_CancelledByUserId",
                table: "Tenders");

            migrationBuilder.DropIndex(
                name: "IX_Tenders_CancelledByUserId",
                table: "Tenders");

            migrationBuilder.DropColumn(
                name: "CancellationReason",
                table: "Tenders");

            migrationBuilder.DropColumn(
                name: "CancelledAt",
                table: "Tenders");

            migrationBuilder.DropColumn(
                name: "CancelledByUserId",
                table: "Tenders");
        }
    }
}
