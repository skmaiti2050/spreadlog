import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../profile/presentation/providers/profile_providers.dart';
import '../../flights/domain/aircraft_type_summary.dart';
import '../../flights/domain/ledger_totals.dart';
import '../domain/sacaa_summary_slip_generator.dart';

/// Screen to preview, print, or export the official SACAA Career / Renewal Logbook Summary Slip.
/// Directly synchronizes with the pilot's centralized Pilot Profile credentials.
class SummarySlipPreviewScreen extends ConsumerWidget {
  final List<AircraftTypeSummary> typeSummaries;
  final LedgerTotals grandTotals;

  const SummarySlipPreviewScreen({
    super.key,
    required this.typeSummaries,
    required this.grandTotals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(pilotProfileProvider);
    final slipDate = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Summary Slip (SACAA)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async {
          final bytes = await SacaaSummarySlipPdfGenerator.generateSlip(
            typeSummaries: typeSummaries,
            grandTotals: grandTotals,
            pilotName: profile.pilotName,
            licenceNumber: profile.licenceNumber,
            date: slipDate,
          );
          return Uint8List.fromList(bytes);
        },
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'SACAA_Career_Summary_Slip_${slipDate.year}.pdf',
      ),
    );
  }
}
