import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../reports/domain/sacaa_pdf_generator.dart';
import '../../flights/domain/ledger_page.dart';

/// Clean, simple screen to preview, print, or share the official statutory SACAA logbook PDF.
class PdfPreviewScreen extends StatelessWidget {
  final List<LedgerPage> pages;
  final String pilotName;
  final String licenceNumber;

  const PdfPreviewScreen({
    super.key,
    required this.pages,
    this.pilotName = 'PILOT IN COMMAND',
    this.licenceNumber = 'ZA-123456',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook PDF Preview (SACAA Appendix A)'),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async {
          final bytes = await SacaaPdfGenerator.generateDocument(
            pages: pages,
            pilotName: pilotName,
            licenceNumber: licenceNumber,
          );
          return Uint8List.fromList(bytes);
        },
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'SACAA_Logbook_${DateTime.now().year}.pdf',
      ),
    );
  }
}

