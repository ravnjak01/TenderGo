using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

public class OfferPdfDocument : IDocument
{
    private readonly OfferPdfModel _model;

    public OfferPdfDocument(OfferPdfModel model)
    {
        _model = model;
    }

    public DocumentMetadata GetMetadata() => DocumentMetadata.Default;

    public void Compose(IDocumentContainer container)
    {
        container.Page(page =>
        {
            page.Margin(40);
            page.Size(PageSizes.A4);
            page.DefaultTextStyle(x => x.FontSize(11).FontFamily("Arial"));

            page.Header().Element(ComposeHeader);
            page.Content().Element(ComposeContent);

            page.Footer().AlignCenter().Text(x =>
            {
                x.Span("Generated on ");
                x.Span(DateTime.Now.ToString("dd.MM.yyyy HH:mm")).SemiBold();
            });
        });
    }

    void ComposeHeader(IContainer container)
    {
        container.Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                col.Item().Text("ACCEPTED TENDER REPORT")
                    .FontSize(20)
                    .Bold()
                   .FontColor(Colors.Blue.Darken3);

                col.Item().Text($"Ref. No: {_model.ReferenceNumber}")
                    .FontSize(11)
                    .Bold()
                    .FontColor(Colors.Grey.Darken2);

                col.Item().Text($"Date: {_model.Date:dd.MM.yyyy}")
                    .FontSize(10)
                    .FontColor(Colors.Grey.Darken1);
            });

            row.ConstantItem(100).AlignRight().Text("TenderGo")
                .Bold()
                .FontSize(14)
                .FontColor(Colors.Blue.Darken3);
        });
    }

    void ComposeContent(IContainer container)
    {
        container.PaddingTop(20).Column(col =>
        {
            col.Spacing(20);

            col.Item().Element(ComposeDetails);
            col.Item().Element(ComposeTable);
            
            col.Item().PaddingTop(10).AlignRight().Text("Status: ACCEPTED")
                .FontSize(12)
                .Bold()
                .FontColor(Colors.Green.Medium);
        });
    }

    void ComposeDetails(IContainer container)
    {
        container.Background(Colors.Grey.Lighten4).Padding(12).Column(col =>
        {
            col.Spacing(6);

            col.Item().Text(x =>
            {
                x.Span("Tender Name: ").Bold();
                x.Span(_model.TenderName);
            });

            col.Item().Text(x =>
            {
                x.Span("Client / Investor: ").Bold();
                x.Span(_model.ClientName);
            });

            col.Item().Text(x =>
            {
                x.Span("Contractor: ").Bold();
                x.Span($"{_model.FirstName} {_model.LastName}");
            });
        });
    }

    void ComposeTable(IContainer container)
    {
        container.Table(table =>
        {
            table.ColumnsDefinition(columns =>
            {
                columns.RelativeColumn(1);
                columns.RelativeColumn(2);
            });

            table.Header(header =>
            {
                header.Cell().Background(Colors.Blue.Darken3).Padding(6).Text("Specification Field").Bold().FontColor(Colors.White);
                header.Cell().Background(Colors.Blue.Darken3).Padding(6).Text("Details / Value").Bold().FontColor(Colors.White);
            });

            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text("Reference Number").Bold();
            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text(_model.ReferenceNumber);

            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text("Tender").Bold();
            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text(_model.TenderName);

            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text("Client").Bold();
            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text(_model.ClientName);

            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text("Contractor").Bold();
            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text($"{_model.FirstName} {_model.LastName}");

            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text("Acceptance Date").Bold();
            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text(_model.Date.ToString("dd.MM.yyyy HH:mm"));

            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text("Total Contract Amount").Bold();
            table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(6).Text($"{_model.Amount:N2} KM").Bold().FontColor(Colors.Green.Darken2);
        });
    }
}