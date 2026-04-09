using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TenderGo.Services.Migrations
{
    /// <inheritdoc />
    public partial class UpdatedBid : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "DeliveryNote",
                table: "Bids",
                newName: "Proposal");

            migrationBuilder.AlterColumn<string>(
                name: "LocationName",
                table: "Tenders",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Country",
                table: "Tenders",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AddColumn<int>(
                name: "DeliveryDays",
                table: "Bids",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeliveryDays",
                table: "Bids");

            migrationBuilder.RenameColumn(
                name: "Proposal",
                table: "Bids",
                newName: "DeliveryNote");

            migrationBuilder.AlterColumn<string>(
                name: "LocationName",
                table: "Tenders",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Country",
                table: "Tenders",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");
        }
    }
}
