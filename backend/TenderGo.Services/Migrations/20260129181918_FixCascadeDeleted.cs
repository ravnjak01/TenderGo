using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TenderGo.Services.Migrations
{
    /// <inheritdoc />
    public partial class FixCascadeDeleted : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Tenders_AspNetUsers_CreatedByUserId",
                table: "Tenders");

            migrationBuilder.AlterColumn<string>(
                name: "CreatedByUserId",
                table: "Tenders",
                type: "nvarchar(450)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(450)",
                oldNullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "TenderApplications",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AlterColumn<string>(
                name: "SubmittedByUserId",
                table: "Bids",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Bids",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_Bids_SubmittedByUserId",
                table: "Bids",
                column: "SubmittedByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Bids_AspNetUsers_SubmittedByUserId",
                table: "Bids",
                column: "SubmittedByUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Tenders_AspNetUsers_CreatedByUserId",
                table: "Tenders",
                column: "CreatedByUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Bids_AspNetUsers_SubmittedByUserId",
                table: "Bids");

            migrationBuilder.DropForeignKey(
                name: "FK_Tenders_AspNetUsers_CreatedByUserId",
                table: "Tenders");

            migrationBuilder.DropIndex(
                name: "IX_Bids_SubmittedByUserId",
                table: "Bids");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "TenderApplications");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Bids");

            migrationBuilder.AlterColumn<string>(
                name: "CreatedByUserId",
                table: "Tenders",
                type: "nvarchar(450)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AlterColumn<string>(
                name: "SubmittedByUserId",
                table: "Bids",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AddForeignKey(
                name: "FK_Tenders_AspNetUsers_CreatedByUserId",
                table: "Tenders",
                column: "CreatedByUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id");
        }
    }
}
