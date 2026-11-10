import '../../aircraft/domain/aircraft_model.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_pdf_preview.dart';
import '../../../../core/widgets/hint_banner.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../../flights/domain/aircraft_type_summary.dart';
import '../../flights/domain/ledger_totals.dart';
import '../../flights/domain/flight_filter.dart';
import '../../flights/domain/ledger_calculator.dart';
import '../../flights/presentation/providers/flights_providers.dart';
import '../../flights/presentation/widgets/flight_filter_dialog.dart';
import '../../aircraft/presentation/providers/aircraft_providers.dart';
import '../domain/sacaa_summary_slip_generator.dart';

/// Screen to preview, print, or export the official SACAA Career / Renewal Logbook Summary Slip.
/// Directly synchronizes with the pilot's centralized Pilot Profile credentials.
class SummarySlipPreviewScreen extends ConsumerStatefulWidget {
  final List<AircraftTypeSummary> typeSummaries;
  final LedgerTotals grandTotals;
  final FlightFilter initialFilter;

  const SummarySlipPreviewScreen({
    super.key,
    required this.typeSummaries,
    required this.grandTotals,
    this.initialFilter = const FlightFilter(),
  });

  @override
  ConsumerState<SummarySlipPreviewScreen> createState() =>
      _SummarySlipPreviewScreenState();
}

class _SummarySlipPreviewScreenState
    extends ConsumerState<SummarySlipPreviewScreen> {
  late FlightFilter filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final flights = ref.watch(flightsStreamProvider);
    final models = <String, AircraftModel>{
      for (final model
          in ref.watch(allAircraftModelsProvider).value ??
              const <AircraftModel>[])
        model.id: model,
    };
    final selected = filter.apply(flights.value ?? [], models: models);
    const calculator = LedgerCalculator();
    final typeSummaries = calculator.calculateTotalsByType(selected);
    final grandTotals = calculator.calculateTotals(selected);
    final profile = ref.watch(pilotProfileProvider);
    final slipDate = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Summary Slip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Period & filters'),
                  onPressed: () async {
                    final result = await FlightFilterDialog.show(
                      context,
                      initial: filter,
                      flights: flights.value ?? [],
                    );
                    if (result != null && mounted) {
                      setState(() => filter = result);
                    }
                  },
                ),
                Text('${filter.periodLabel} · ${selected.length} flights'),
              ],
            ),
          ),
          if (flights.isLoading) const LinearProgressIndicator(),
          if (flights.hasError)
            const Text('Could not load flights. Please retry.'),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: HintBanner(
              hintKey: 'hint_summary_slip_purpose',
              message: 'The Career Summary Slip aggregates career hours by aircraft type. Use the print icon to export or save as PDF.',
              margin: EdgeInsets.zero,
            ),
          ),

          if (flights.isLoading || flights.hasError)
            Expanded(
              child: Center(
                child: flights.hasError
                    ? TextButton(
                        onPressed: () => ref.invalidate(flightsStreamProvider),
                        child: const Text('Retry loading flights'),
                      )
                    : const CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: AppPdfPreview(
                buildPdf: (format) async {
                  final bytes = await SacaaSummarySlipPdfGenerator.generateSlip(
                    typeSummaries: typeSummaries,
                    grandTotals: grandTotals,
                    pilotName: profile.pilotName,
                    licenceNumber: profile.licenceNumber,
                    date: slipDate,
                    selectionLabel: filter.description,
                  );
                  return Uint8List.fromList(bytes);
                },
                fileName:
                    'Summary_${filter.periodLabel.replaceAll(" ", "_")}.pdf',
              ),
            ),
        ],
      ),
    );
  }
}
