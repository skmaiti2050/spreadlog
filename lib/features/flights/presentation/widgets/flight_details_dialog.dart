import 'package:flutter/material.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../aircraft/domain/aircraft_model.dart';
import '../../domain/flight.dart';
import '../../domain/flight_time.dart';

enum FlightDetailsAction { edit, delete }

/// Detailed briefing dialog showcasing the full breakdown of a logged flight,
/// its SACAA statutory column mapping, and options to edit or delete.
class FlightDetailsDialog extends StatelessWidget {
  final Flight flight;

  const FlightDetailsDialog({super.key, required this.flight});

  static Future<FlightDetailsAction?> show(
    BuildContext context, {
    required Flight flight,
  }) {
    return showDialog<FlightDetailsAction>(
      context: context,
      builder: (context) => FlightDetailsDialog(flight: flight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        '${flight.date.day.toString().padLeft(2, '0')}/${flight.date.month.toString().padLeft(2, '0')}/${flight.date.year}';

    final totalMins = flight.totalDurationMinutes;
    final primaryFt = flight.flightTimes.isNotEmpty ? flight.flightTimes.first : null;

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(Icons.flight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      flight.registration,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (flight.aircraftModelId != null &&
                        flight.aircraftModelId!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          flight.aircraftModelId!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary Metrics Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      context,
                      'Total Duration',
                      TimeUtils.formatMinutesToHhMm(totalMins),
                      '${TimeUtils.formatMinutesToDecimal(totalMins)} hrs',
                    ),
                    Container(height: 36, width: 1, color: theme.colorScheme.outlineVariant),
                    _buildStat(
                      context,
                      'Landings',
                      '${flight.landings.totalCount}',
                      '${flight.landings.dayCount} Day / ${flight.landings.nightCount} Night',
                    ),
                    if (flight.soloCrossCountry) ...[
                      Container(height: 36, width: 1, color: theme.colorScheme.outlineVariant),
                      _buildStat(
                        context,
                        'Solo XC',
                        'CAR 61.01.5',
                        'Verified',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Operational Class & Role
              _buildSectionHeader(context, 'Flight Details'),
              const SizedBox(height: 6),
              _buildInfoRow(context, 'PIC Name', flight.picName),
              if (flight.isFstd) ...[
                _buildInfoRow(context, 'Session Type', 'Flight Simulation Training Device (FSTD)'),
                _buildInfoRow(context, 'FSTD Time', TimeUtils.formatMinutesToHhMm(flight.fstdActualMinutes)),
              ] else if (primaryFt != null) ...[
                _buildInfoRow(context, 'Aircraft Class', primaryFt.aircraftClass == AircraftClass.singleEngine ? 'Single Engine (SE)' : 'Multi Engine (ME)'),
                _buildInfoRow(context, 'Operating Role', _roleName(primaryFt.role)),
                _buildInfoRow(context, 'Flight Period', primaryFt.period == TimePeriod.day ? 'Day' : 'Night'),
              ],

              // Instrument Time & Navaids
              if (flight.instrumentTime != null && !flight.instrumentTime!.isEmpty) ...[
                const SizedBox(height: 12),
                _buildSectionHeader(context, 'Instrument Flying & Navaids'),
                const SizedBox(height: 6),
                if (flight.instrumentTime!.actualMinutes > 0)
                  _buildInfoRow(context, 'Actual Instrument', TimeUtils.formatMinutesToHhMm(flight.instrumentTime!.actualMinutes)),
                if (flight.instrumentTime!.fstdMinutes > 0)
                  _buildInfoRow(context, 'FSTD / Sim Instrument', TimeUtils.formatMinutesToHhMm(flight.instrumentTime!.fstdMinutes)),
                if (flight.instrumentTime!.navaids != null && flight.instrumentTime!.navaids!.isNotEmpty)
                  _buildInfoRow(context, 'Navaids / Approaches', flight.instrumentTime!.navaids!),
              ],

              // Remarks & Route
              if (flight.remarks.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSectionHeader(context, 'Route & Remarks'),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    flight.remarks,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // SACAA 32-Column Allocation Badge
              _buildSacaaBadge(context, theme, flight),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          label: const Text('Delete', style: TextStyle(color: Colors.red)),
          onPressed: () => Navigator.of(context).pop(FlightDetailsAction.delete),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Flight'),
          onPressed: () => Navigator.of(context).pop(FlightDetailsAction.edit),
        ),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String title, String value, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _roleName(PilotRole role) {
    switch (role) {
      case PilotRole.pic:
        return 'Pilot-In-Command (PIC)';
      case PilotRole.dual:
        return 'Dual (Instruction Received)';
      case PilotRole.picus:
        return 'PICUS (Under Supervision)';
      case PilotRole.copilot:
        return 'Copilot (SIC)';
    }
  }

  Widget _buildSacaaBadge(BuildContext context, ThemeData theme, Flight flight) {
    String colTarget;
    final totalMins = flight.totalDurationMinutes;

    if (flight.isFstd) {
      colTarget = 'Col 13 (FSTD Actual)';
    } else if (flight.flightTimes.isNotEmpty) {
      final ft = flight.flightTimes.first;
      if (ft.aircraftClass == AircraftClass.singleEngine) {
        if (ft.period == TimePeriod.day) {
          switch (ft.role) {
            case PilotRole.dual: colTarget = 'Col 14 (SE Day Dual)'; break;
            case PilotRole.pic: colTarget = 'Col 15 (SE Day PIC)'; break;
            case PilotRole.picus: colTarget = 'Col 16 (SE Day PICUS)'; break;
            case PilotRole.copilot: colTarget = 'Col 17 (SE Day Copilot)'; break;
          }
        } else {
          switch (ft.role) {
            case PilotRole.dual: colTarget = 'Col 18 (SE Night Dual)'; break;
            case PilotRole.pic: colTarget = 'Col 19 (SE Night PIC)'; break;
            case PilotRole.picus: colTarget = 'Col 20 (SE Night PICUS)'; break;
            case PilotRole.copilot: colTarget = 'Col 21 (SE Night Copilot)'; break;
          }
        }
      } else {
        if (ft.period == TimePeriod.day) {
          switch (ft.role) {
            case PilotRole.dual: colTarget = 'Col 22 (ME Day Dual)'; break;
            case PilotRole.pic: colTarget = 'Col 23 (ME Day PIC)'; break;
            case PilotRole.picus: colTarget = 'Col 24 (ME Day PICUS)'; break;
            case PilotRole.copilot: colTarget = 'Col 25 (ME Day Copilot)'; break;
          }
        } else {
          switch (ft.role) {
            case PilotRole.dual: colTarget = 'Col 26 (ME Night Dual)'; break;
            case PilotRole.pic: colTarget = 'Col 27 (ME Night PIC)'; break;
            case PilotRole.picus: colTarget = 'Col 28 (ME Night PICUS)'; break;
            case PilotRole.copilot: colTarget = 'Col 29 (ME Night Copilot)'; break;
          }
        }
      }
    } else {
      colTarget = 'Recorded in Ledger';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.table_chart_outlined, size: 18, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'SACAA 32-Column Logbook Allocation:\n$colTarget: ${TimeUtils.formatMinutesToHhMm(totalMins)}'
              '${flight.landings.dayCount > 0 ? " • Col 30: ${flight.landings.dayCount} Day Ldg" : ""}'
              '${flight.landings.nightCount > 0 ? " • Col 31: ${flight.landings.nightCount} Night Ldg" : ""}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
