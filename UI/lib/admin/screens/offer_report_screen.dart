import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../shared/services/pdf_service.dart'; // Uvezi tvoj servis

class OfferReportScreen extends StatefulWidget {
  final int offerId;

  const OfferReportScreen({Key? key, required this.offerId}) : super(key: key);

  @override
  State<OfferReportScreen> createState() => _OfferReportScreenState();
}

class _OfferReportScreenState extends State<OfferReportScreen> {
  final PdfService _pdfService = PdfService();
  Uint8List? _pdfBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  void _loadPdf() async {
  try {
    print("Započeto preuzimanje PDF-a za ID: ${widget.offerId}");
    
    // Pozivamo servis koji MORA da okinuti endpoint offers/$id/download-pdf
    final bytes = await _pdfService.fetchOfferPdf(widget.offerId);
    
    setState(() {
      _pdfBytes = bytes;
      _isLoading = false;
    });
  } catch (e) {
    print("Greška unutar ekrana pri učitavanju PDF-a: $e");
    setState(() {
      _isLoading = false; // Zaustavi krug ako pukne
    });
  }
}

  //zadnje dosao,vrti samo ovaj ekran kad se otvori

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pregled Izvještaja"),
        backgroundColor: Colors.blue[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Učitavanje dok API ne vrati fajl
          : _pdfBytes == null
              ? const Center(child: Text("Nemate dozvolu za ovaj izvještaj ili je došlo do greške."))
              : PdfPreview(
                  // Ključna funkcija koja prosjeđuje bajtove paketu za prikaz
                  build: (format) => _pdfBytes!, 
                  allowPrinting: true, // Omogućava dugme za print
                  allowSharing: true,  // Omogućava dugme za download/share na Viber, WhatsApp, Mail...
                  canChangePageFormat: false, // Blokiramo promjenu formata jer je fiksiran na A4 unutar QuestPDF-a
                  pdfFileName: "Prihvacena_Ponuda_${widget.offerId}.pdf",
                ),
    );
  }
}