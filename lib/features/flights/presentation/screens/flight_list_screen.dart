import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/hint_banner.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/edit_profile_dialog.dart';
import '../../../reports/presentation/widgets/print_reminder_banner.dart';
import '../../domain/flight.dart';
import '../providers/flights_providers.dart';
import '../widgets/flight_details_dialog.dart';
import '../widgets/log_flight_dialog.dart';
import '../../../../core/utils/plural.dart';
import '../../../../core/layout/responsive.dart';

class FlightListScreen extends ConsumerStatefulWidget {
  const FlightListScreen({super.key});

  @override
  ConsumerState<FlightListScreen> createState() => _FlightListScreenState();
}

class _FlightListScreenState extends ConsumerState<FlightListScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedFlightIds = {};
  String _searchFilter = '';

  Future<void> _openEditFlightDialog(Flight flight) async {
    try {
      final updated = await LogFlightDialog.show(
        context,
        initialFlight: flight,
      );
      if (updated != null) {
        await ref.read(flightsRepositoryProvider).saveFlight(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Flight ${updated.registration} (${TimeUtils.formatMinutesToHhMm(updated.totalDurationMinutes)}) updated successfully',
              ),
              backgroundColor: Colors.green.shade800,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update flight: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _showFlightDetails(Flight flight) async {
    final action = await FlightDetailsDialog.show(context, flight: flight);
    if (!mounted || action == null) return;

    if (action == FlightDetailsAction.edit) {
      await _openEditFlightDialog(flight);
    } else if (action == FlightDetailsAction.delete) {
      await _confirmDeleteFlight(flight);
    }
  }

  Future<void> _openLogFlightDialog() async {
    try {
      final flight = await LogFlightDialog.show(context);
      if (flight != null) {
        await ref.read(flightsRepositoryProvider).saveFlight(flight);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Flight ${flight.registration} (${TimeUtils.formatMinutesToHhMm(flight.totalDurationMinutes)}) logged successfully',
              ),
              backgroundColor: Colors.green.shade800,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save flight: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteFlight(Flight flight) async {
    final dateStr =
        '${flight.date.day.toString().padLeft(2, '0')}/${flight.date.month.toString().padLeft(2, '0')}/${flight.date.year}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Flight Entry?'),
        content: Text(
          'Are you sure you want to delete flight ${flight.registration} on $dateStr (${TimeUtils.formatMinutesToHhMm(flight.totalDurationMinutes)})?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(flightsRepositoryProvider).deleteFlight(flight.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Flight entry deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete flight: $e'),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmBatchDelete() async {
    if (_selectedFlightIds.isEmpty) return;
    final count = _selectedFlightIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete ${plural(count, 'flight entry', 'flight entries')}?',
        ),
        content: Text(
          'Are you sure you want to delete ${plural(count, 'selected flight entry', 'selected flight entries')}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete ($count)'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(flightsRepositoryProvider)
            .deleteFlights(_selectedFlightIds.toList());
        final deletedCount = _selectedFlightIds.length;
        setState(() {
          _selectedFlightIds.clear();
          _isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${plural(deletedCount, 'flight')} deleted'),
              backgroundColor: Colors.green.shade800,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete flights: $e'),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flightsAsync = ref.watch(flightsStreamProvider);
    final totals = ref.watch(grandTotalsProvider);
    final profile = ref.watch(pilotProfileProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraNarrow = screenWidth < 380;

    final visibleFlights = (flightsAsync.value ?? <Flight>[])
        .where(
          (f) =>
              _searchFilter.isEmpty ||
              f.registration.toLowerCase().contains(_searchFilter) ||
              (f.aircraftModelId?.toLowerCase().contains(_searchFilter) ??
                  false) ||
              f.remarks.toLowerCase().contains(_searchFilter) ||
              f.picName.toLowerCase().contains(_searchFilter),
        )
        .toList();
    final visibleIds = visibleFlights.map((f) => f.id).toSet();
    // Reconcile local selection whenever the stream or search changes.
    _selectedFlightIds.retainAll(visibleIds);
    if (visibleIds.isEmpty) _isSelectionMode = false;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Exit selection mode',
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedFlightIds.clear();
                  });
                },
              ),
              title: Text('${_selectedFlightIds.length} Selected'),
              actions: [
                flightsAsync.maybeWhen(
                  data: (flights) => IconButton(
                    icon: const Icon(Icons.select_all),
                    tooltip: 'Select All',
                    onPressed: () {
                      setState(() {
                        if (_selectedFlightIds.length == visibleIds.length) {
                          _selectedFlightIds.clear();
                        } else {
                          _selectedFlightIds.addAll(visibleIds);
                        }
                      });
                    },
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Delete Selected',
                  onPressed: _selectedFlightIds.isNotEmpty
                      ? _confirmBatchDelete
                      : null,
                ),
              ],
            )
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Spreadlog',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.isComplete)
                    Text(
                      '${profile.pilotName} • ${profile.licenceNumber}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    // Name and licence print on every logbook page, so
                    // prompt for them instead of showing invented values.
                    InkWell(
                      onTap: () => EditProfileDialog.show(context),
                      child: Text(
                        'Set up your pilot profile ›',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                if (visibleIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.checklist),
                    tooltip: 'Select Multiple',
                    onPressed: () => setState(() => _isSelectionMode = true),
                  ),
              ],
            ),
      body: ContentWidth(
        child: Column(
          children: [
            // Totals summary header card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(14),
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
                    TimeUtils.formatMinutesToHhMm(
                      totals.totalFlightTimeMinutes,
                    ),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Divider(height: 16),
                  if (isUltraNarrow)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetricColumn(
                              context,
                              'Single Engine',
                              TimeUtils.formatMinutesToHhMm(
                                totals.totalSingleEngine,
                              ),
                            ),
                            _buildMetricColumn(
                              context,
                              'Multi Engine',
                              TimeUtils.formatMinutesToHhMm(
                                totals.totalMultiEngine,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                    )
                  else
                    // Wrap rather than Row: at large text sizes the four
                    // metrics flow onto a second line instead of overflowing.
                    // Full width so spaceBetween has room to spread them.
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 16,
                        runSpacing: 10,
                        children: [
                          _buildMetricColumn(
                            context,
                            'Single Engine',
                            TimeUtils.formatMinutesToHhMm(
                              totals.totalSingleEngine,
                            ),
                          ),
                          _buildMetricColumn(
                            context,
                            'Multi Engine',
                            TimeUtils.formatMinutesToHhMm(
                              totals.totalMultiEngine,
                            ),
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
                    ),
                ],
              ),
            ),

            // Search / Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText:
                      'Search by registration, aircraft type, or remarks...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _searchFilter.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchFilter = ''),
                        )
                      : null,
                ),
                onChanged: (v) =>
                    setState(() => _searchFilter = v.trim().toLowerCase()),
              ),
            ),

            // Flight list
            Expanded(
              child: flightsAsync.when(
                data: (flights) {
                  if (flights.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                          ],
                        ),
                      ),
                    );
                  }

                  // Apply search filter if present
                  final filteredFlights = visibleFlights;

                  if (filteredFlights.isEmpty) {
                    return const Center(
                      child: Text('No flights match your search query.'),
                    );
                  }

                  return Column(
                    children: [
                      const PrintReminderBanner(),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        child: HintBanner(
                          hintKey: 'hint_flight_card_details',
                          message: 'Tap any flight card for its briefing breakdown • Tap the pencil icon to edit in place.',
                          margin: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount: filteredFlights.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final flight = filteredFlights[index];
                              return _buildFlightCard(context, flight);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text('Error loading flights: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              heroTag: 'flight_list_fab',
              onPressed: _openLogFlightDialog,
              icon: const Icon(Icons.add),
              label: const Text('Log Flight'),
            ),
    );
  }

  Widget _buildMetricColumn(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    // Read "Single Engine 01:30" as one item, not every label then every
    // value.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.8,
              ),
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
      ),
    );
  }

  Widget _buildFlightCard(BuildContext context, Flight flight) {
    final theme = Theme.of(context);
    final dateStr = TimeUtils.formatLogbookDate(flight.date);
    final isSelected = _selectedFlightIds.contains(flight.id);

    return Card(
      elevation: 0,
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedFlightIds.add(flight.id);
          });
        },
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedFlightIds.remove(flight.id);
                if (_selectedFlightIds.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                _selectedFlightIds.add(flight.id);
              }
            });
          } else {
            _showFlightDetails(flight);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedFlightIds.add(flight.id);
                      } else {
                        _selectedFlightIds.remove(flight.id);
                        if (_selectedFlightIds.isEmpty) {
                          _isSelectionMode = false;
                        }
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
              ] else ...[
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.flight),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          flight.registration,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (flight.aircraftModelId != null &&
                            flight.aircraftModelId!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
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
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PIC: ${flight.picName}${flight.remarks.isNotEmpty ? ' • ${flight.remarks}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(
                            TimeUtils.formatMinutesToHhMm(
                              flight.totalDurationMinutes,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        if (flight.landings.totalCount > 0)
                          Chip(
                            avatar: const Icon(Icons.flight_land, size: 14),
                            label: Text(
                              plural(flight.landings.totalCount, 'ldg'),
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        if (flight.soloCrossCountry)
                          const Chip(
                            label: Text(
                              'Solo XC',
                              style: TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Flight',
                  onPressed: () => _openEditFlightDialog(flight),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Delete Flight',
                  onPressed: () => _confirmDeleteFlight(flight),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
