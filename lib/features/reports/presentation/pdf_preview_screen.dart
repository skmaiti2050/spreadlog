import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_pdf_preview.dart';

import '../../reports/domain/sacaa_pdf_generator.dart';
import '../../flights/domain/ledger_page.dart';
import 'providers/print_reminder_providers.dart';

/// Clean, simple screen to preview, print, or share the official statutory SACAA logbook PDF.
class PdfPreviewScreen extends ConsumerWidget {
  final List<LedgerPage> pages;
  final String pilotName;
  final String licenceNumber;

  const PdfPreviewScreen({
    super.key,
    required this.pages,
    this.pilotName = '',
    this.licenceNumber = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook PDF Preview'),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: AppPdfPreview(
        buildPdf: (format) async {
          final bytes = await SacaaPdfGenerator.generateDocument(
            pages: pages,
            pilotName: pilotName,
            licenceNumber: licenceNumber,
          );
          return Uint8List.fromList(bytes);
        },
        fileName: 'Pilot_Logbook_${DateTime.now().year}.pdf',
        // Printing or sharing the PDF counts as the 90-day paper copy.
        onOutput: () =>
            unawaited(ref.read(lastPrintedProvider.notifier).markPrinted()),
      ),
    );
  }
}
