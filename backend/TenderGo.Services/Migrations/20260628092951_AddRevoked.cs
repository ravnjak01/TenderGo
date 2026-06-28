using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TenderGo.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddRevoked : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Ratings_Tenders_TenderId",
                table: "Ratings");

            migrationBuilder.DropForeignKey(
                name: "FK_UserActivites_Tenders_TenderId",
                table: "UserActivites");

            migrationBuilder.DropPrimaryKey(
                name: "PK_UserActivites",
                table: "UserActivites");

            migrationBuilder.DropColumn(
                name: "NameChangeCount",
                table: "AspNetUsers");

            migrationBuilder.RenameTable(
                name: "UserActivites",
                newName: "UserActivities");

            migrationBuilder.RenameIndex(
                name: "IX_UserActivites_TenderId",
                table: "UserActivities",
                newName: "IX_UserActivities_TenderId");

            migrationBuilder.AlterColumn<string>(
                name: "UserId",
                table: "UserActivities",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddPrimaryKey(
                name: "PK_UserActivities",
                table: "UserActivities",
                column: "Id");

            migrationBuilder.CreateTable(
                name: "RevokedTokens",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Jti = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    RevokedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RevokedTokens", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RevokedTokens_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserActivities_UserId",
                table: "UserActivities",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_RevokedTokens_Jti",
                table: "RevokedTokens",
                column: "Jti",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RevokedTokens_UserId",
                table: "RevokedTokens",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Ratings_Tenders_TenderId",
                table: "Ratings",
                column: "TenderId",
                principalTable: "Tenders",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserActivities_AspNetUsers_UserId",
                table: "UserActivities",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_UserActivities_Tenders_TenderId",
                table: "UserActivities",
                column: "TenderId",
                principalTable: "Tenders",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Ratings_Tenders_TenderId",
                table: "Ratings");

            migrationBuilder.DropForeignKey(
                name: "FK_UserActivities_AspNetUsers_UserId",
                table: "UserActivities");

            migrationBuilder.DropForeignKey(
                name: "FK_UserActivities_Tenders_TenderId",
                table: "UserActivities");

            migrationBuilder.DropTable(
                name: "RevokedTokens");

            migrationBuilder.DropPrimaryKey(
                name: "PK_UserActivities",
                table: "UserActivities");

            migrationBuilder.DropIndex(
                name: "IX_UserActivities_UserId",
                table: "UserActivities");

            migrationBuilder.RenameTable(
                name: "UserActivities",
                newName: "UserActivites");

            migrationBuilder.RenameIndex(
                name: "IX_UserActivities_TenderId",
                table: "UserActivites",
                newName: "IX_UserActivites_TenderId");

            migrationBuilder.AddColumn<int>(
                name: "NameChangeCount",
                table: "AspNetUsers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AlterColumn<string>(
                name: "UserId",
                table: "UserActivites",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AddPrimaryKey(
                name: "PK_UserActivites",
                table: "UserActivites",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Ratings_Tenders_TenderId",
                table: "Ratings",
                column: "TenderId",
                principalTable: "Tenders",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_UserActivites_Tenders_TenderId",
                table: "UserActivites",
                column: "TenderId",
                principalTable: "Tenders",
                principalColumn: "Id");
        }
    }
}
