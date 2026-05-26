import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';

class AdminReportPreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String title;

  const AdminReportPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.title,
  });

  @override
  State<AdminReportPreviewScreen> createState() => _AdminReportPreviewScreenState();
}

class _AdminReportPreviewScreenState extends State<AdminReportPreviewScreen> {
  String? _localFilePath;
  bool _isSaving = false;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isPdfReady = false;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  @override
  void initState() {
    super.initState();
    _preparePdfFile();
  }

  // flutter_pdfview zahtijeva privremeni fajl na disku da bi ga učitao na nekim platformama
  Future<void> _preparePdfFile() async {
    try {
      final tempDir = await getTemporaryDirectory();
      // 🌟 Riješena greška 1: DateTime.now promijenjeno u DateTime.now()
      final tempFile = File('${tempDir.path}/temp_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await tempFile.writeAsBytes(widget.pdfBytes);
      
      setState(() {
        _localFilePath = tempFile.path;
      });
    } catch (e) {
      SnackbarHelper.show(context, 'Greška prilikom pripreme PDF-a: $e', isError: true);
    }
  }

  // Funkcija za trajno čuvanje dokumenta u Downloads/Documents folderu
  Future<void> _savePdfToDevice() async {
    setState(() => _isSaving = true);
    try {
      Directory? targetDir;
      
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final cleanTitle = widget.title.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
      final finalFile = File('${targetDir!.path}/$cleanTitle.pdf');
      await finalFile.writeAsBytes(widget.pdfBytes);

      if (!mounted) return;
      SnackbarHelper.show(
        context, 
        Platform.isAndroid 
            ? 'Izvještaj uspješno sačuvan u Downloads!' 
            : 'Izvještaj sačuvan u Documents!',
        isError: false
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.show(context, 'Neuspješno čuvanje fajla: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save_alt_rounded),
                  tooltip: 'Preuzmi na uređaj',
                  onPressed: _savePdfToDevice,
                ),
          const SizedBox(width: 8),
        ],
      ),
    body: widget.pdfBytes.isEmpty
          ? const Center(child: Text('Nema podataka za prikaz izvještaja.'))
          : Stack(
              children: [
                // 🌟 ZAMIJENI STARI PDFView SA OVIM:
                SfPdfViewer.memory(
                  widget.pdfBytes,
                  controller: _pdfViewerController,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _totalPages = _pdfViewerController.pageCount;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      _currentPage = details.newPageNumber - 1;
                    });
                  },
                ),
                
                // Indikator stranica u donjem desnom uglu
                if (_totalPages > 0)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Text(
                        '${_currentPage + 1} / $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}