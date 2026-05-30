import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  State<AdminReportPreviewScreen> createState() =>
      _AdminReportPreviewScreenState();
}

class _AdminReportPreviewScreenState extends State<AdminReportPreviewScreen> {
  bool _isSaving = false;
  int _totalPages = 0;
  int _currentPage = 0;
  final PdfViewerController _pdfViewerController = PdfViewerController();

  Future<void> _savePdfToDevice() async {
    setState(() => _isSaving = true);

    try {
      if (widget.pdfBytes.isEmpty) {
        throw Exception('Nema podataka za spremanje.');
      }

      final cleanTitle = widget.title
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .replaceAll(' ', '_');
      final fileName = cleanTitle.isEmpty ? 'izvjestaj.pdf' : '$cleanTitle.pdf';
      String? savedPath;

      if (Platform.isAndroid || Platform.isIOS) {
        Directory? targetDir;

        if (Platform.isAndroid) {
          targetDir = Directory('/storage/emulated/0/Download');
          if (!await targetDir.exists()) {
            targetDir = await getExternalStorageDirectory();
          }
        } else {
          targetDir = await getApplicationDocumentsDirectory();
        }

        if (targetDir == null) {
          throw Exception('Nije moguce pronaci folder za spremanje.');
        }

        final finalFile = File('${targetDir.path}/$fileName');
        await finalFile.writeAsBytes(widget.pdfBytes);
        savedPath = finalFile.path;
      } else {
        savedPath = await FilePicker.saveFile(
          dialogTitle: 'Spremi izvjestaj',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const ['pdf'],
          bytes: widget.pdfBytes,
        );

        if (savedPath == null) {
          if (!mounted) return;
          SnackbarHelper.show(context, 'Spremanje fajla je otkazano.');
          return;
        }

        await File(savedPath).writeAsBytes(widget.pdfBytes);
      }

      if (!mounted) return;
      SnackbarHelper.show(
        context,
        Platform.isAndroid
            ? 'Izvjestaj uspjesno sacuvan u Downloads!'
            : 'Izvjestaj uspjesno sacuvan: $savedPath',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        'Neuspjesno cuvanje fajla: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save_alt_rounded),
                  tooltip: 'Preuzmi na uredaj',
                  onPressed: _savePdfToDevice,
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.pdfBytes.isEmpty
          ? const Center(child: Text('Nema podataka za prikaz izvjestaja.'))
          : Stack(
              children: [
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
                if (_totalPages > 0)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
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
