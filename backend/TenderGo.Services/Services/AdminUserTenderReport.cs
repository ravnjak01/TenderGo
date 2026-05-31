using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using System;
using System.Collections.Generic;

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
            page.Margin(40);
            page.Size(PageSizes.A4);
            page.DefaultTextStyle(x => x.FontSize(10).FontFamily("Arial"));

            page.Header().Element(ComposeHeader);
            page.Content().Element(ComposeContent);

            page.Footer().AlignCenter().Text(x =>
            {
                x.Span("Stranica ").FontSize(9);
                x.CurrentPageNumber().FontSize(9).Bold();
                x.Span(" od ").FontSize(9);
                x.TotalPages().FontSize(9).Bold();
            });
        });
    }

    // 🔹 HEADER: Informacije o sistemu i korisniku za kojeg se pravi izvještaj
    void ComposeHeader(IContainer container)
    {
        container.Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                col.Item().Text("IZVJEŠTAJ O KORISNIČKIM TENDERIMA")
                    .FontSize(18)
                    .Bold()
                    .FontColor(Colors.Blue.Darken3);

                col.Item().PaddingTop(4).Text(x =>
                {
                    x.Span("Korisnik: ").Bold();
                    x.Span(_model.UserName).Medium();
                });

                col.Item().Text($"Datum generisanja: {DateTime.Now:dd.MM.yyyy HH:mm}")
                    .FontSize(9)
                    .FontColor(Colors.Grey.Darken1);
            });

            row.ConstantItem(100).AlignRight().Text("TenderGo")
                .Bold()
                .FontSize(16)
                .FontColor(Colors.Blue.Darken3);
        });
    }

    // 🔹 CONTENT: Prolazak kroz listu tendera
    void ComposeContent(IContainer container)
    {
        container.PaddingTop(20).Column(col =>
        {
            col.Spacing(25); // Razmak između različitih tendera

            if (_model.Tenders == null || _model.Tenders.Count == 0)
            {
                col.Item().Text("Korisnik trenutno nema kreiranih tendera.")
                    .Italic()
                    .FontColor(Colors.Grey.Darken1);
                return;
            }

            foreach (var tender in _model.Tenders)
            {
                col.Item().Element(c => ComposeTenderSection(c, tender));
            }
        });
    }

    // 🔹 TENDER SECTION: Pojedinačni tender sa svojim podacima i tabelom ponuda
    void ComposeTenderSection(IContainer container, TenderWithOffers tender)
    {
        container.Border(1)
                 .BorderColor(Colors.Grey.Lighten2)
                 .Background(Colors.White)
                 .Column(col =>
        {
            // Zaglavlje sekcije tendera (Siva traka sa detaljima tendera)
            col.Item().Background(Colors.Grey.Lighten4).Padding(10).Row(row =>
            {
                row.RelativeItem().Column(tenderCol =>
                {
                    tenderCol.Item().Text(tender.TenderTitle)
                        .FontSize(12)
                        .Bold()
                        .FontColor(Colors.Blue.Darken4);

                    tenderCol.Item().Text($"Kreiran: {tender.CreatedAt:dd.MM.yyyy HH:mm}")
                        .FontSize(9)
                        .FontColor(Colors.Grey.Darken2);
                });

                // Status tendera sa desne strane
                var statusColor = GetTenderStatusColor(tender.Status);
                row.ConstantItem(100).AlignRight().AlignMiddle()
                    .Text($"STATUS: {tender.Status.ToUpper()}")
                    .FontSize(10)
                    .Bold()
                    .FontColor(statusColor);
            });

            // Sadržaj unutar sekcije (Tabela ponuda)
            col.Item().Padding(10).Column(innerCol =>
            {
                innerCol.Spacing(8);
                innerCol.Item().Text("Primljene ponude:").Bold().FontSize(10).FontColor(Colors.Grey.Darken3);

                if (tender.Offers == null || tender.Offers.Count == 0)
                {
                    innerCol.Item().PaddingLeft(5).Text("Nema primljenih ponuda za ovaj tender.")
                        .Italic()
                        .FontColor(Colors.Grey.Darken1);
                }
                else
                {
                    innerCol.Item().Element(c => ComposeOffersTable(c, tender.Offers));
                }
            });
        });
    }

    // 🔹 OFFERS TABLE: Tabela sa ponudama za taj specifičan tender
    void ComposeOffersTable(IContainer container, List<OfferItem> offers)
    {
        container.Table(table =>
        {
            table.ColumnsDefinition(columns =>
            {
                columns.RelativeColumn(3); // Ponuđač
                columns.RelativeColumn(2); // Datum ponude
                columns.RelativeColumn(2); // Status ponude
                columns.RelativeColumn(2); // Iznos (KM)
            });

            // Tabelarno zaglavlje (Mali plavi header unutar kartice)
            table.Header(header =>
            {
                var headerBg = Colors.Blue.Darken1;
                header.Cell().Background(headerBg).Padding(5).Text("Ponuđač").Bold().FontColor(Colors.White).FontSize(9);
                header.Cell().Background(headerBg).Padding(5).Text("Datum slanja").Bold().FontColor(Colors.White).FontSize(9);
                header.Cell().Background(headerBg).Padding(5).Text("Status ponude").Bold().FontColor(Colors.White).FontSize(9);
                header.Cell().Background(headerBg).Padding(5).AlignRight().Text("Cijena (KM)").Bold().FontColor(Colors.White).FontSize(9);
            });

            // Redovi tabele (Podaci o ponudama)
            bool alternate = false;
            foreach (var offer in offers)
            {
                var rowBg = alternate ? Colors.Grey.Lighten5 : Colors.White;

                table.Cell().Background(rowBg).BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(5).Text(offer.BidderName).FontSize(9);
                table.Cell().Background(rowBg).BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(5).Text($"{offer.Date:dd.MM.yyyy HH:mm}").FontSize(9);
                
                // Status ponude (tekstualno obojen)
                var offerStatusColor = GetOfferStatusColor(offer.Status);
                table.Cell().Background(rowBg).BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(5).Text(offer.Status).FontSize(9).Bold().FontColor(offerStatusColor);
                
                table.Cell().Background(rowBg).BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(5).AlignRight().Text($"{offer.Amount:N2} KM").FontSize(9).Bold();

                alternate = !alternate;
            }
        });
    }

    // 🎨 Pomoćne metode za dinamičko bojenje statusa tendera
    private string GetTenderStatusColor(string status)
    {
        return status?.ToLower() switch
        {
            "active" or "otvoren" => Colors.Green.Medium,
            "closed" or "zatvoren" => Colors.Red.Medium,
            "draft" => Colors.Grey.Darken1,
            _ => Colors.Blue.Medium
        };
    }

    // 🎨 Pomoćne metode za dinamičko bojenje statusa ponuda
    private string GetOfferStatusColor(string status)
    {
        return status?.ToLower() switch
        {
            "accepted" or "prihvaćena" => Colors.Green.Darken2,
            "rejected" or "odbijena" => Colors.Red.Darken2,
            "pending" or "na čekanju" => Colors.Orange.Darken3,
            _ => Colors.Grey.Darken3
        };
    }
}