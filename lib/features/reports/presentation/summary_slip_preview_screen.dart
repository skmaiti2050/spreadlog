import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../profile/presentation/providers/profile_providers.dart';
import '../../flights/domain/aircraft_type_summary.dart';
import '../../flights/domain/ledger_totals.dart';
import '../domain/sacaa_summary_slip_generator.dart';

/// Screen allowing pilots to preview, customize credentials for, and print/export
/// the official SACAA Career / Renewal Logbook Summary Slip.
class SummarySlipPreviewScreen extends ConsumerStatefulWidget {
  final List<AircraftTypeSummary> typeSummaries;
  final LedgerTotals grandTotals;
  final String initialPilotName;
  final String initialLicenceNumber;

  const SummarySlipPreviewScreen({
    super.key,
    required this.typeSummaries,
    required this.grandTotals,
    this.initialPilotName = 'PILOT IN COMMAND',
    this.initialLicenceNumber = 'ZA-123456',
  });

  @override
  ConsumerState<SummarySlipPreviewScreen> createState() =>
      _SummarySlipPreviewScreenState();
}

class _SummarySlipPreviewScreenState
    extends ConsumerState<SummarySlipPreviewScreen> {
  late String _pilotName;
  late String _licenceNumber;
  late DateTime _slipDate;

  @override
  void initState() {
    super.initState();
    _pilotName = widget.initialPilotName;
    _licenceNumber = widget.initialLicenceNumber;
    _slipDate = DateTime.now();
  }

  void _showEditCredentialsDialog() {
    final nameController = TextEditingController(text: _pilotName);
    final licenceController = TextEditingController(text: _licenceNumber);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Slip Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Pilot Name',
                hintText: 'e.g. CAPT J. DOE',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: licenceController,
              decoration: const InputDecoration(
                labelText: 'Licence Number',
                hintText: 'e.g. ZA-123456',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = nameController.text.trim().isNotEmpty
                  ? nameController.text.trim()
                  : 'PILOT IN COMMAND';
              final newLicence = licenceController.text.trim().isNotEmpty
                  ? licenceController.text.trim()
                  : 'ZA-123456';
              setState(() {
                _pilotName = newName;
                _licenceNumber = newLicence;
              });
              ref.read(pilotProfileProvider.notifier).updateProfile(
                    pilotName: newName,
                    licenceNumber: newLicence,
                  );
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Summary Slip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Edit Pilot Name & Licence',
            onPressed: _showEditCredentialsDialog,
          ),
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
            typeSummaries: widget.typeSummaries,
            grandTotals: widget.grandTotals,
            pilotName: _pilotName,
            licenceNumber: _licenceNumber,
            date: _slipDate,
          );
          return Uint8List.fromList(bytes);
        },
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'SACAA_Career_Summary_Slip_${_slipDate.year}.pdf',
      ),
    );
  }
}
