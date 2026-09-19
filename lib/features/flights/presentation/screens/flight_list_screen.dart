import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aviation_theme.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/hint_banner.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/edit_profile_dialog.dart';
import '../../../reports/presentation/pdf_preview_screen.dart';
import '../../../reports/presentation/summary_slip_preview_screen.dart';
import '../../domain/flight.dart';
import '../providers/flights_providers.dart';
import '../widgets/flight_details_dialog.dart';
import '../widgets/log_flight_dialog.dart';
import 'physical_logbook_screen.dart';

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
      final updated =
          await LogFlightDialog.show(context, initialFlight: flight);
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Flight entry deleted')),
          );
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
        title: Text('Delete $count Flight Entries?'),
        content: Text(
          'Are you sure you want to delete $count selected flight entries?\nThis action cannot be undone.',
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
              content: Text('$deletedCount flights deleted successfully'),
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
    final isNarrow = screenWidth < 460;
    final isUltraNarrow = screenWidth < 380;
    final activeTheme = ref.watch(aviationThemeProvider);

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
                        if (_selectedFlightIds.length == flights.length) {
                          _selectedFlightIds.clear();
                        } else {
                          _selectedFlightIds
                              .addAll(flights.map((f) => f.id));
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
                    'Aviation Logbook',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${profile.pilotName} • ${profile.licenceNumber}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              actions: isNarrow
                  ? [
                      IconButton(
                        icon: const Icon(Icons.account_circle_outlined),
                        tooltip: 'Pilot Profile',
                        onPressed: () => EditProfileDialog.show(context),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'Actions & Views',
                        onSelected: (action) {
                          switch (action) {
                            case 'checklist':
                              setState(() => _isSelectionMode = true);
                              break;
                            case 'logbook':
                              final pages = ref.read(ledgerPagesProvider);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      PhysicalLogbookScreen(pages: pages),
                                ),
                              );
                              break;
                            case 'pdf':
                              final pages = ref.read(ledgerPagesProvider);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PdfPreviewScreen(
                                    pages: pages,
                                    pilotName: profile.pilotName,
                                    licenceNumber: profile.licenceNumber,
                                  ),
                                ),
                              );
                              break;
                            case 'slip':
                              final typeSummaries =
                                  ref.read(aircraftTypeSummariesProvider);
                              final grandTotals = ref.read(grandTotalsProvider);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SummarySlipPreviewScreen(
                                    typeSummaries: typeSummaries,
                                    grandTotals: grandTotals,
                                  ),
                                ),
                              );
                              break;
                            case 'theme':
                              ref
                                  .read(aviationThemeProvider.notifier)
                                  .cycleNext();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'checklist',
                            child: ListTile(
                              leading: Icon(Icons.checklist),
                              title: Text('Select Multiple'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logbook',
                            child: ListTile(
                              leading: Icon(Icons.menu_book),
                              title: Text('Physical Logbook (SACAA)'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'pdf',
                            child: ListTile(
                              leading: Icon(Icons.picture_as_pdf),
                              title: Text('Export SACAA PDF'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'slip',
                            child: ListTile(
                              leading: Icon(Icons.receipt_long),
                              title: Text('Career Summary Slip'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'theme',
                            child: ListTile(
                              leading: Icon(activeTheme.icon),
                              title: Text(
                                  'Theme: ${activeTheme.displayName.split(" ").first}'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ]
                  : [
                      IconButton(
                        icon: const Icon(Icons.checklist),
                        tooltip: 'Select Multiple',
                        onPressed: () => setState(() => _isSelectionMode = true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu_book),
                        tooltip: 'Physical Logbook View',
                        onPressed: () {
                          final pages = ref.read(ledgerPagesProvider);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PhysicalLogbookScreen(pages: pages),
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
                              builder: (_) => PdfPreviewScreen(
                                pages: pages,
                                pilotName: profile.pilotName,
                                licenceNumber: profile.licenceNumber,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.receipt_long),
                        tooltip: 'Career Summary Slip',
                        onPressed: () {
                          final typeSummaries =
                              ref.read(aircraftTypeSummariesProvider);
                          final grandTotals = ref.read(grandTotalsProvider);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SummarySlipPreviewScreen(
                                typeSummaries: typeSummaries,
                                grandTotals: grandTotals,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(activeTheme.icon),
                        tooltip:
                            'Switch Theme (${activeTheme.displayName.split(" ").first})',
                        onPressed: () =>
                            ref.read(aviationThemeProvider.notifier).cycleNext(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.account_circle_outlined),
                        tooltip: 'Pilot Profile',
                        onPressed: () => EditProfileDialog.show(context),
                      ),
                    ],
            ),
      body: Column(
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
                  TimeUtils.formatMinutesToHhMm(totals.totalFlightTimeMinutes),
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
                                totals.totalSingleEngine),
                          ),
                          _buildMetricColumn(
                            context,
                            'Multi Engine',
                            TimeUtils.formatMinutesToHhMm(
                                totals.totalMultiEngine),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricColumn(
                        context,
                        'Single Engine',
                        TimeUtils.formatMinutesToHhMm(
                            totals.totalSingleEngine),
                      ),
                      _buildMetricColumn(
                        context,
                        'Multi Engine',
                        TimeUtils.formatMinutesToHhMm(
                            totals.totalMultiEngine),
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

          // Search / Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by registration, aircraft type, or remarks...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchFilter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchFilter = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchFilter = v.trim().toLowerCase()),
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
                            onPressed: _openLogFlightDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Flight'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Apply search filter if present
                final filteredFlights = _searchFilter.isEmpty
                    ? flights
                    : flights.where((f) {
                        return f.registration.toLowerCase().contains(_searchFilter) ||
                            (f.aircraftModelId?.toLowerCase().contains(_searchFilter) ?? false) ||
                            f.remarks.toLowerCase().contains(_searchFilter) ||
                            f.picName.toLowerCase().contains(_searchFilter);
                      }).toList();

                if (filteredFlights.isEmpty) {
                  return const Center(
                    child: Text('No flights match your search query.'),
                  );
                }

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _openLogFlightDialog,
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

  Widget _buildFlightCard(BuildContext context, Flight flight) {
    final theme = Theme.of(context);
    final dateStr =
        '${flight.date.day.toString().padLeft(2, '0')}/${flight.date.month.toString().padLeft(2, '0')}/${flight.date.year}';
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
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
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
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              flight.aircraftModelId!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    theme.colorScheme.onSecondaryContainer,
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
                                flight.totalDurationMinutes),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        if (flight.landings.totalCount > 0)
                          Chip(
                            avatar: const Icon(Icons.flight_land, size: 14),
                            label: Text('${flight.landings.totalCount} ldgs',
                                style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        if (flight.soloCrossCountry)
                          const Chip(
                            label: Text('Solo XC',
                                style: TextStyle(fontSize: 11)),
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
