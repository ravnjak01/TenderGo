using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TenderGo.Services.Migrations
{
    /// <inheritdoc />
    public partial class FixTenderApplicationRelationship : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TenderApplications_AspNetUsers_UserId1",
                table: "TenderApplications");

            migrationBuilder.DropIndex(
                name: "IX_TenderApplications_UserId1",
                table: "TenderApplications");

            migrationBuilder.DropColumn(
                name: "UserId1",
                table: "TenderApplications");

            migrationBuilder.AlterColumn<string>(
                name: "UserId",
                table: "TenderApplications",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.CreateIndex(
                name: "IX_TenderApplications_UserId",
                table: "TenderApplications",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_TenderApplications_AspNetUsers_UserId",
                table: "TenderApplications",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TenderApplications_AspNetUsers_UserId",
                table: "TenderApplications");

            migrationBuilder.DropIndex(
                name: "IX_TenderApplications_UserId",
                table: "TenderApplications");

            migrationBuilder.AlterColumn<int>(
                name: "UserId",
                table: "TenderApplications",
                type: "int",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AddColumn<string>(
                name: "UserId1",
                table: "TenderApplications",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_TenderApplications_UserId1",
                table: "TenderApplications",
                column: "UserId1");

            migrationBuilder.AddForeignKey(
                name: "FK_TenderApplications_AspNetUsers_UserId1",
                table: "TenderApplications",
                column: "UserId1",
                principalTable: "AspNetUsers",
                principalColumn: "Id");
        }
    }
}
