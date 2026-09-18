import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../aircraft/domain/aircraft_model.dart';
import '../../domain/flight.dart';
import '../../domain/flight_time.dart';
import '../../domain/landings.dart';
import '../../../reports/presentation/pdf_preview_screen.dart';
import '../providers/flights_providers.dart';
import 'physical_logbook_screen.dart';

class FlightListScreen extends ConsumerWidget {
  const FlightListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightsAsync = ref.watch(flightsStreamProvider);
    final totals = ref.watch(grandTotalsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aviation Logbook',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Physical Logbook View',
            onPressed: () {
              final pages = ref.read(ledgerPagesProvider);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PhysicalLogbookScreen(pages: pages),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export SACAA PDF',
            onPressed: () {
              final pages = ref.read(ledgerPagesProvider);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PdfPreviewScreen(pages: pages),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Flight',
            onPressed: () => _showAddSampleFlightDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Totals summary header card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL FLIGHT TIME',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      '${TimeUtils.formatMinutesToDecimal(totals.totalFlightTimeMinutes)} hrs',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  TimeUtils.formatMinutesToHhMm(totals.totalFlightTimeMinutes),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricColumn(
                      context,
                      'Single Engine',
                      TimeUtils.formatMinutesToHhMm(totals.totalSingleEngine),
                    ),
                    _buildMetricColumn(
                      context,
                      'Multi Engine',
                      TimeUtils.formatMinutesToHhMm(totals.totalMultiEngine),
                    ),
                    _buildMetricColumn(
                      context,
                      'Day / Night',
                      '${TimeUtils.formatMinutesToHhMm(totals.totalDay)} / ${TimeUtils.formatMinutesToHhMm(totals.totalNight)}',
                    ),
                    _buildMetricColumn(
                      context,
                      'Landings',
                      '${totals.totalLandings}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Flight list
          Expanded(
            child: flightsAsync.when(
              data: (flights) {
                if (flights.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flight_takeoff,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No flights recorded yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first flight entry to begin calculating totals.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () =>
                                _showAddSampleFlightDialog(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Test Flight'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: flights.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final flight = flights[index];
                    return _buildFlightCard(context, ref, flight);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading flights: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSampleFlightDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log Flight'),
      ),
    );
  }

  Widget _buildMetricColumn(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildFlightCard(BuildContext context, WidgetRef ref, Flight flight) {
    final theme = Theme.of(context);
    final dateStr =
        '${flight.date.day.toString().padLeft(2, '0')}/${flight.date.month.toString().padLeft(2, '0')}/${flight.date.year}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          foregroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.flight),
        ),
        title: Row(
          children: [
            Text(
              flight.registration,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('PIC: ${flight.picName}${flight.remarks.isNotEmpty ? ' • ${flight.remarks}' : ''}'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text(
                    TimeUtils.formatMinutesToHhMm(flight.totalDurationMinutes),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                if (flight.landings.totalCount > 0)
                  Chip(
                    avatar: const Icon(Icons.flight_land, size: 16),
                    label: Text('${flight.landings.totalCount} ldgs'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                if (flight.soloCrossCountry)
                  const Chip(
                    label: Text('Solo XC'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: 'Delete Flight',
          onPressed: () async {
            await ref.read(flightsRepositoryProvider).deleteFlight(flight.id);
          },
        ),
      ),
    );
  }

  void _showAddSampleFlightDialog(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final sampleFlight = Flight(
      id: 'flight_${DateTime.now().millisecondsSinceEpoch}',
      date: now,
      registration: 'ZS-EXT',
      picName: 'SELF',
      remarks: 'FALA - FAGM Local Training',
      soloCrossCountry: false,
      flightTimes: const [
        FlightTime(
          aircraftClass: AircraftClass.singleEngine,
          period: TimePeriod.day,
          role: PilotRole.pic,
          durationMinutes: 90, // 01:30
        ),
      ],
      landings: const Landings(dayCount: 2),
      createdAt: now,
      updatedAt: now,
    );

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Flight Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Log a standard flight entry:'),
            const SizedBox(height: 8),
            Text('• Registration: ${sampleFlight.registration}'),
            Text('• PIC: ${sampleFlight.picName}'),
            Text('• Duration: ${TimeUtils.formatMinutesToHhMm(sampleFlight.totalDurationMinutes)} (90 mins)'),
            const Text('• Single Engine Day PIC'),
            Text('• Landings: ${sampleFlight.landings.dayCount} day'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(flightsRepositoryProvider).saveFlight(sampleFlight);
            },
            child: const Text('Save Flight'),
          ),
        ],
      ),
    );
  }
}
