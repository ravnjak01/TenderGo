using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using TenderGo.Models.Entities;

public class AdminTenderReportDocument : IDocument
{
    private readonly List<Tender> _tenders;
    private readonly DateTime? _from;
    private readonly DateTime? _to;

    public AdminTenderReportDocument(List<Tender> tenders, DateTime? from, DateTime? to)
    {
        _tenders = tenders;
        _from = from;
        _to = to;
    }

    public DocumentMetadata GetMetadata() => DocumentMetadata.Default;

    public void Compose(IDocumentContainer container)
    {
        container.Page(page =>
        {
            page.Margin(35);
            page.Size(PageSizes.A4);
            page.DefaultTextStyle(x => x.FontSize(9).FontFamily("Arial"));

            page.Header().Element(ComposeHeader);
            page.Content().Element(ComposeContent);
            page.Footer().AlignCenter().Text(x =>
            {
                x.Span("Page ").FontSize(9);
                x.CurrentPageNumber().FontSize(9).Bold();
                x.Span(" of ").FontSize(9);
                x.TotalPages().FontSize(9).Bold();
            });
        });
    }

    private void ComposeHeader(IContainer container)
    {
        container.Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                col.Item().Text("TENDERS BY LOCATION")
                    .FontSize(18)
                    .Bold()
                    .FontColor(Colors.Blue.Darken3);

                col.Item().PaddingTop(4).Text(GetPeriodText())
                    .FontSize(10)
                    .FontColor(Colors.Grey.Darken2);

                col.Item().Text($"Generated: {DateTime.Now:dd.MM.yyyy HH:mm}")
                    .FontSize(8)
                    .FontColor(Colors.Grey.Darken1);
            });

            row.ConstantItem(100).AlignRight().Text("TenderGo")
                .Bold()
                .FontSize(15)
                .FontColor(Colors.Blue.Darken3);
        });
    }

    private void ComposeContent(IContainer container)
    {
        container.PaddingTop(18).Column(col =>
        {
            col.Spacing(14);

            col.Item().Element(ComposeSummary);

            if (_tenders.Count == 0)
            {
                col.Item().PaddingTop(10).Text("No tenders found for the selected period.")
                    .Italic()
                    .FontColor(Colors.Grey.Darken1);
                return;
            }

            var groupedTenders = _tenders
                .GroupBy(t => GetLocationKey(t))
                .OrderBy(g => g.Key.Country)
                .ThenBy(g => g.Key.Region)
                .ThenBy(g => g.Key.Name);

            foreach (var locationGroup in groupedTenders)
            {
                col.Item().Element(c => ComposeLocationGroup(c, locationGroup));
            }
        });
    }

    private void ComposeSummary(IContainer container)
    {
        var totalBudget = _tenders.Sum(t => t.MaxBudget);

        container.Background(Colors.Grey.Lighten4).Padding(10).Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                col.Item().Text("Total tenders").FontColor(Colors.Grey.Darken2);
                col.Item().Text(_tenders.Count.ToString()).FontSize(14).Bold();
            });

            row.RelativeItem().Column(col =>
            {
                col.Item().Text("Locations").FontColor(Colors.Grey.Darken2);
                col.Item().Text(_tenders.Select(t => t.LocationId).Distinct().Count().ToString()).FontSize(14).Bold();
            });

            row.RelativeItem().Column(col =>
            {
                col.Item().Text("Total budget").FontColor(Colors.Grey.Darken2);
                col.Item().Text($"{totalBudget:N2} KM").FontSize(14).Bold().FontColor(Colors.Green.Darken2);
            });
        });
    }

    private void ComposeLocationGroup(IContainer container, IGrouping<LocationKey, Tender> locationGroup)
    {
        var tenders = locationGroup
            .OrderByDescending(t => t.CreatedAt)
            .ToList();

        container.Column(col =>
        {
            col.Item().Background(Colors.Blue.Darken3).Padding(8).Row(row =>
            {
                row.RelativeItem().Text(GetLocationTitle(locationGroup.Key))
                    .Bold()
                    .FontSize(11)
                    .FontColor(Colors.White);

                row.ConstantItem(120).AlignRight().Text($"{tenders.Count} tender(s)")
                    .Bold()
                    .FontSize(10)
                    .FontColor(Colors.White);
            });

            col.Item().Element(c => ComposeTenderTable(c, tenders));
        });
    }

    private void ComposeTenderTable(IContainer container, List<Tender> tenders)
    {
        container.Table(table =>
        {
            table.ColumnsDefinition(columns =>
            {
                columns.RelativeColumn(3);
                columns.RelativeColumn(2);
                columns.RelativeColumn(2);
                columns.RelativeColumn(2);
                columns.RelativeColumn(2);
                columns.RelativeColumn(2);
            });

            table.Header(header =>
            {
                HeaderCell(header, "Tender");
                HeaderCell(header, "Category");
                HeaderCell(header, "Created");
                HeaderCell(header, "Deadline");
                HeaderCell(header, "Status");
                HeaderCell(header, "Budget");
            });

            var alternate = false;
            foreach (var tender in tenders)
            {
                var background = alternate ? Colors.Grey.Lighten5 : Colors.White;

                BodyCell(table, background, tender.Title);
                BodyCell(table, background, tender.Category?.Name ?? "-");
                BodyCell(table, background, tender.CreatedAt.ToString("dd.MM.yyyy"));
                BodyCell(table, background, tender.Deadline.ToString("dd.MM.yyyy"));
                BodyCell(table, background, tender.Status.ToString(), GetStatusColor(tender.Status.ToString()));
                BodyCell(table, background, $"{tender.MaxBudget:N2} KM", alignRight: true);

                alternate = !alternate;
            }
        });
    }

    private static void HeaderCell(TableCellDescriptor table, string text)
    {
        table.Cell()
            .Background(Colors.Grey.Darken2)
            .Padding(5)
            .Text(text)
            .Bold()
            .FontColor(Colors.White)
            .FontSize(8);
    }

    private static void BodyCell(
        TableDescriptor table,
        string background,
        string text,
        string? fontColor = null,
        bool alignRight = false)
    {
        var cell = table.Cell()
            .Background(background)
            .BorderBottom(1)
            .BorderColor(Colors.Grey.Lighten3)
            .Padding(5);

        var textDescriptor = alignRight ? cell.AlignRight().Text(text) : cell.Text(text);
        textDescriptor.FontSize(8);

        if (!string.IsNullOrWhiteSpace(fontColor))
        {
            textDescriptor.Bold().FontColor(fontColor);
        }
    }

    private string GetPeriodText()
    {
        var fromText = _from.HasValue ? _from.Value.ToString("dd.MM.yyyy") : "beginning";
        var toText = _to.HasValue ? _to.Value.ToString("dd.MM.yyyy") : "today";

        return $"Period: {fromText} - {toText}";
    }

    private static LocationKey GetLocationKey(Tender tender)
    {
        return new LocationKey(
            tender.Location?.Name ?? "Unknown location",
            tender.Location?.Country ?? string.Empty,
            tender.Location?.Region ?? string.Empty);
    }

    private static string GetLocationTitle(LocationKey location)
    {
        var parts = new[] { location.Name, location.Region, location.Country }
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct()
            .ToArray();

        return string.Join(", ", parts);
    }

    private static string GetStatusColor(string status)
    {
        return status.ToLower() switch
        {
            "open" => Colors.Green.Darken2,
            "closed" => Colors.Orange.Darken3,
            "awarded" => Colors.Blue.Darken2,
            "cancelled" => Colors.Red.Darken2,
            _ => Colors.Grey.Darken3
        };
    }

    private sealed record LocationKey(string Name, string Country, string Region);
}
