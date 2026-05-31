import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../shared/services/pdf_service.dart';

class OfferReportScreen extends StatefulWidget {
  final int offerId;

  const OfferReportScreen({super.key, required this.offerId});

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
      final bytes = await _pdfService.fetchOfferPdf(widget.offerId);
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pregled Izvještaja"),
        backgroundColor: Colors.blue[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfBytes == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Nemate dozvolu za ovaj izvještaj ili je došlo do greške.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : PdfPreview(
                  build: (format) => _pdfBytes!,
                  allowPrinting: true, // Printanje radi kroz native mobilni print manager
                  allowSharing: true,  // Otvara standardni mobilni Share Sheet (Viber, WhatsApp...)
                  canChangePageFormat: false, // Sakriva desktop opcije za promjenu formata papira
                  canChangeOrientation: false, // Sakriva kontrole za rotaciju stranice
                  canDebug: false, // Osigurava da nema debug UI elemenata
                  pdfFileName: "Prihvacena_Ponuda_${widget.offerId}.pdf",
                ),
    );
  }
}