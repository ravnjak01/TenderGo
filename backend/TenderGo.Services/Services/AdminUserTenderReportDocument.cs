using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using System;
using System.Collections.Generic;
using System.Linq;
using TenderGo.Models.DTOs;

public class AdminUserTenderReportDocument : IDocument
{
    private readonly AdminUserTenderReportModel _model;

    public AdminUserTenderReportDocument(AdminUserTenderReportModel model)
    {
        _model = model;
    }

    public DocumentMetadata GetMetadata() => DocumentMetadata.Default;

    public void Compose(IDocumentContainer container)
    {
        container.Page(page =>
        {
            page.Size(PageSizes.A4);
            page.Margin(35);
            page.DefaultTextStyle(x => x.FontSize(9).FontFamily("Arial"));

            page.Header().Element(ComposeHeader);
            page.Content().Element(ComposeContent);

            page.Footer().AlignCenter().Text(x =>
            {
                x.Span("Stranica ");
                x.CurrentPageNumber();
                x.Span(" / ");
                x.TotalPages();
            });
        });
    }

    private void ComposeHeader(IContainer container)
    {
        container.Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                col.Item().Text("IZVJEŠTAJ KORISNIKA")
                    .FontSize(18)
                    .Bold()
                    .FontColor(Colors.Blue.Darken3);

                col.Item().PaddingTop(4).Text($"Korisnik: {_model.UserName}")
                    .FontSize(11);

                col.Item().Text($"Generisano: {DateTime.Now:dd.MM.yyyy HH:mm}")
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

            if (_model.Tenders.Count == 0)
            {
                col.Item().Text("Korisnik nema kreiranih tendera.")
                    .Italic()
                    .FontColor(Colors.Grey.Darken1);
                return;
            }

            foreach (var tender in _model.Tenders)
            {
                col.Item().Element(c => ComposeTender(c, tender));
            }
        });
    }

    private void ComposeSummary(IContainer container)
    {
        var totalOffers = _model.Tenders.Sum(t => t.Offers.Count);
        var totalBudget = _model.Tenders.Sum(t => t.MaxBudget);

        container.Background(Colors.Grey.Lighten4).Padding(10).Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                col.Item().Text("Broj tendera").FontColor(Colors.Grey.Darken2);
                col.Item().Text(_model.Tenders.Count.ToString()).FontSize(14).Bold();
            });

            row.RelativeItem().Column(col =>
            {
                col.Item().Text("Ukupno ponuda").FontColor(Colors.Grey.Darken2);
                col.Item().Text(totalOffers.ToString()).FontSize(14).Bold();
            });

            
        });
    }

    private void ComposeTender(IContainer container, TenderWithOffers tender)
    {
        container.Border(1)
            .BorderColor(Colors.Grey.Lighten2)
            .Padding(10)
            .Column(col =>
            {
                col.Item().Row(row =>
                {
                    row.RelativeItem().Text(tender.TenderTitle)
                        .Bold()
                        .FontSize(12);

                    row.ConstantItem(100).AlignRight().Text(tender.Status)
                        .Bold()
                        .FontColor(GetStatusColor(tender.Status));
                });

                col.Item().PaddingTop(4).Text(
                    $"Kategorija: {tender.CategoryName} | Lokacija: {tender.LocationName}"
                ).FontSize(8).FontColor(Colors.Grey.Darken2);

                col.Item().Text(
                    $"Kreiran: {tender.CreatedAt:dd.MM.yyyy} | Rok: {tender.Deadline:dd.MM.yyyy} | Budžet: {tender.MaxBudget:N2} KM"
                ).FontSize(8).FontColor(Colors.Grey.Darken2);

                col.Item().PaddingTop(8);

                if (!tender.Offers.Any())
                {
                    col.Item().Text("Nema pristiglih ponuda.").Italic();
                    return;
                }

                col.Item().Element(c => ComposeOffersTable(c, tender.Offers));
            });
    }

    private void ComposeOffersTable(IContainer container, List<OfferItem> offers)
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
            });

            table.Header(header =>
            {
                header.Cell().Element(c => HeaderCell(c, "Ponuđač"));
                header.Cell().Element(c => HeaderCell(c, "Iznos"));
                header.Cell().Element(c => HeaderCell(c, "Rok isporuke"));
                header.Cell().Element(c => HeaderCell(c, "Status"));
                header.Cell().Element(c => HeaderCell(c, "Datum"));
            });

            var alternate = false;

            foreach (var offer in offers)
            {
                var background = alternate ? Colors.Grey.Lighten5 : Colors.White;

                ComposeBodyCell(table.Cell(), background, offer.BidderName);
                ComposeBodyCell(table.Cell(), background, $"{offer.Amount:N2} KM", alignRight: true);
                ComposeBodyCell(table.Cell(), background, offer.DeliveryDays.ToString(), alignRight: true);
                ComposeBodyCell(table.Cell(), background, offer.Status, GetStatusColor(offer.Status));
                ComposeBodyCell(table.Cell(), background, offer.Date.ToString("dd.MM.yyyy"));

                alternate = !alternate;
            }
        });
    }

    private static void HeaderCell(IContainer container, string text)
    {
        container
            .Background(Colors.Blue.Darken3)
            .Padding(5)
            .Text(text)
            .Bold()
            .FontColor(Colors.White)
            .FontSize(8);
    }

    private static void ComposeBodyCell(
        IContainer container,
        string background,
        string text,
        string? fontColor = null,
        bool alignRight = false)
    {
        var cell = container
            .Background(background)
            .BorderBottom(1)
            .BorderColor(Colors.Grey.Lighten3)
            .Padding(5);

        var textDescriptor = alignRight
            ? cell.AlignRight().Text(text)
            : cell.Text(text);

        textDescriptor.FontSize(8);

        if (!string.IsNullOrWhiteSpace(fontColor))
        {
            textDescriptor.Bold().FontColor(fontColor);
        }
    }

    private static string GetStatusColor(string status)
    {
        return status.ToLower() switch
        {
            "open" => Colors.Green.Darken2,
            "closed" => Colors.Orange.Darken3,
            "awarded" => Colors.Blue.Darken2,
            "cancelled" => Colors.Red.Darken2,
            "pending" => Colors.Orange.Darken3,
            "accepted" => Colors.Green.Darken2,
            "rejected" => Colors.Red.Darken2,
            "withdrawn" => Colors.Grey.Darken2,
            _ => Colors.Grey.Darken3
        };
    }
}