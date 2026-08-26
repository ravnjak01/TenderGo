using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TenderGo.Services.Migrations
{
    /// <inheritdoc />
    public partial class UpdateTenderImages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "CreatedByUserId",
                table: "TenderImages",
                type: "nvarchar(450)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_TenderImages_CreatedByUserId",
                table: "TenderImages",
                column: "CreatedByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_TenderImages_AspNetUsers_CreatedByUserId",
                table: "TenderImages",
                column: "CreatedByUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TenderImages_AspNetUsers_CreatedByUserId",
                table: "TenderImages");

            migrationBuilder.DropIndex(
                name: "IX_TenderImages_CreatedByUserId",
                table: "TenderImages");

            migrationBuilder.AlterColumn<string>(
                name: "CreatedByUserId",
                table: "TenderImages",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");
        }
    }
}
