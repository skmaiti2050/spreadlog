import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/hint_banner.dart';
import '../../../aircraft/domain/aircraft_model.dart';
import '../../../reports/presentation/summary_slip_preview_screen.dart';
import '../providers/flights_providers.dart';
import '../../domain/flight.dart';
import '../../domain/flight_time.dart';
import '../../domain/instruction_time.dart';
import '../../domain/ledger_page.dart';
import '../../domain/ledger_totals.dart';

/// Clean, high-density physical logbook spread screen.
/// Renders the exact 14 flight rows, Brought Forward, Page Totals, and Carried Forward.
class PhysicalLogbookScreen extends ConsumerStatefulWidget {
  final List<LedgerPage> pages;

  const PhysicalLogbookScreen({
    super.key,
    required this.pages,
  });

  @override
  ConsumerState<PhysicalLogbookScreen> createState() => _PhysicalLogbookScreenState();
}

class _PhysicalLogbookScreenState extends ConsumerState<PhysicalLogbookScreen> {
  int _currentPageIndex = 0;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Physical Logbook')),
        body: const Center(child: Text('No flights logged yet.')),
      );
    }

    final safeIndex = _currentPageIndex.clamp(0, widget.pages.length - 1);
    final page = widget.pages[safeIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Physical Logbook — Page ${page.pageNumber} of ${widget.pages.length}'),
        actions: [
          IconButton(
            tooltip: 'Previous Page',
            icon: const Icon(Icons.chevron_left),
            onPressed: safeIndex > 0 ? () => setState(() => _currentPageIndex--) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Text(
              '${page.pageNumber} / ${widget.pages.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Next Page',
            icon: const Icon(Icons.chevron_right),
            onPressed: safeIndex < widget.pages.length - 1 ? () => setState(() => _currentPageIndex++) : null,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Career Summary Slip',
            onPressed: () {
              final typeSummaries = ref.read(aircraftTypeSummariesProvider);
              final totals = ref.read(grandTotalsProvider);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SummarySlipPreviewScreen(
                    typeSummaries: typeSummaries,
                    grandTotals: totals,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: HintBanner(

              hintKey: 'hint_physical_logbook_zoom',
              message: 'Scroll horizontally & vertically to navigate the 32-column ledger • Use top arrows to flip pages • Pinch or double-tap to zoom.',
              margin: EdgeInsets.zero,
            ),
          ),

          Expanded(
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: true,
              trackVisibility: true,
              notificationPredicate: (notif) => notif.metrics.axis == Axis.vertical,
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                trackVisibility: true,
                notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _buildSpreadTable(page),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpreadTable(LedgerPage page) {
    const rowCount = 14;

    return DataTable(
      columnSpacing: 10,
      headingRowHeight: 40,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 36,
      horizontalMargin: 8,
      border: TableBorder.all(color: Colors.white24, width: 0.5),
      headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade900),
      columns: const [
        // Left Page (Columns 1-13)
        DataColumn(label: Text('DATE (1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('TYPE (2)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('REG (3)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('PIC (4)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('DETAILS & REMARKS (5)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('NAV (6)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('PLACE (7)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ACT (8)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SIM (9)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE (10)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME (11)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('FSTD (12)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ACT (13)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),

        // Right Page (Columns 14-32)
        DataColumn(label: Text('SE DUAL D (14)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE PIC D (15)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE PICUS D (16)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE CO D (17)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE DUAL N (18)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE PIC N (19)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE PICUS N (20)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE CO N (21)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME DUAL D (22)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME PIC D (23)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME PICUS D (24)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME CO D (25)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME DUAL N (26)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME PIC N (27)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME PICUS N (28)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME CO N (29)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('LDG D (30)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('LDG N (31)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SIGNATURES / CERT (32)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
      ],
      rows: [
        // 14 standard logbook entries
        for (int i = 0; i < rowCount; i++)
          _buildDataRow(i < page.entries.length ? page.entries[i] : null),

        // Brought Forward
        _buildSummaryRow(
          label: 'BROUGHT FORWARD',
          color: Colors.blueGrey.shade800.withValues(alpha: 0.5),
          totals: page.broughtForward,
        ),

        // Page Totals
        _buildSummaryRow(
          label: 'THIS PAGE TOTAL',
          color: Colors.blueGrey.shade900,
          totals: page.pageTotals,
        ),

        // Carried Forward
        _buildSummaryRow(
          label: 'CARRIED FORWARD',
          color: Colors.indigo.shade900.withValues(alpha: 0.6),
          isBold: true,
          totals: page.carriedForward,
        ),
      ],
    );
  }

  DataRow _buildDataRow(Flight? flight) {
    if (flight == null) {
      return DataRow(
        cells: List.generate(32, (_) => const DataCell(Text(''))),
      );
    }

    final dateStr = '${flight.date.day.toString().padLeft(2, '0')}/${flight.date.month.toString().padLeft(2, '0')}';

    int seDayDual = 0, seDayPic = 0, seDayPicus = 0, seDayCopilot = 0;
    int seNightDual = 0, seNightPic = 0, seNightPicus = 0, seNightCopilot = 0;
    int meDayDual = 0, meDayPic = 0, meDayPicus = 0, meDayCopilot = 0;
    int meNightDual = 0, meNightPic = 0, meNightPicus = 0, meNightCopilot = 0;

    for (final ft in flight.flightTimes) {
      if (ft.aircraftClass == AircraftClass.singleEngine) {
        if (ft.period == TimePeriod.day) {
          switch (ft.role) {
            case PilotRole.dual: seDayDual += ft.durationMinutes; break;
            case PilotRole.pic: seDayPic += ft.durationMinutes; break;
            case PilotRole.picus: seDayPicus += ft.durationMinutes; break;
            case PilotRole.copilot: seDayCopilot += ft.durationMinutes; break;
          }
        } else {
          switch (ft.role) {
            case PilotRole.dual: seNightDual += ft.durationMinutes; break;
            case PilotRole.pic: seNightPic += ft.durationMinutes; break;
            case PilotRole.picus: seNightPicus += ft.durationMinutes; break;
            case PilotRole.copilot: seNightCopilot += ft.durationMinutes; break;
          }
        }
      } else {
        if (ft.period == TimePeriod.day) {
          switch (ft.role) {
            case PilotRole.dual: meDayDual += ft.durationMinutes; break;
            case PilotRole.pic: meDayPic += ft.durationMinutes; break;
            case PilotRole.picus: meDayPicus += ft.durationMinutes; break;
            case PilotRole.copilot: meDayCopilot += ft.durationMinutes; break;
          }
        } else {
          switch (ft.role) {
            case PilotRole.dual: meNightDual += ft.durationMinutes; break;
            case PilotRole.pic: meNightPic += ft.durationMinutes; break;
            case PilotRole.picus: meNightPicus += ft.durationMinutes; break;
            case PilotRole.copilot: meNightCopilot += ft.durationMinutes; break;
          }
        }
      }
    }

    int instructorSe = 0;
    int instructorMe = 0;
    int instructorFstd = 0;
    for (final it in flight.instructionTimes) {
      switch (it.category) {
        case InstructorCategory.singleEngine: instructorSe += it.durationMinutes; break;
        case InstructorCategory.multiEngine: instructorMe += it.durationMinutes; break;
        case InstructorCategory.fstd: instructorFstd += it.durationMinutes; break;
      }
    }

    return DataRow(
      cells: [
        // Left Page (1-13)
        DataCell(Text(dateStr, style: const TextStyle(fontSize: 11))),
        DataCell(Text(flight.aircraftModelId ?? 'AIRCRAFT', style: const TextStyle(fontSize: 11))),
        DataCell(Text(flight.registration, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataCell(Text(flight.picName, style: const TextStyle(fontSize: 11))),
        DataCell(Text(flight.remarks, style: const TextStyle(fontSize: 11))),
        DataCell(Text(flight.instrumentTime?.navaids ?? '', style: const TextStyle(fontSize: 11))),
        DataCell(Text(flight.instrumentTime?.place ?? '', style: const TextStyle(fontSize: 11))),
        _timeCell(flight.instrumentTime?.actualMinutes ?? 0),
        _timeCell(flight.instrumentTime?.fstdMinutes ?? 0),
        _timeCell(instructorSe),
        _timeCell(instructorMe),
        _timeCell(instructorFstd),
        _timeCell(flight.fstdActualMinutes),

        // Right Page (14-32)
        _timeCell(seDayDual),
        _timeCell(seDayPic),
        _timeCell(seDayPicus),
        _timeCell(seDayCopilot),
        _timeCell(seNightDual),
        _timeCell(seNightPic),
        _timeCell(seNightPicus),
        _timeCell(seNightCopilot),
        _timeCell(meDayDual),
        _timeCell(meDayPic),
        _timeCell(meDayPicus),
        _timeCell(meDayCopilot),
        _timeCell(meNightDual),
        _timeCell(meNightPic),
        _timeCell(meNightPicus),
        _timeCell(meNightCopilot),
        DataCell(Text(flight.landings.dayCount > 0 ? '${flight.landings.dayCount}' : '', style: const TextStyle(fontSize: 11))),
        DataCell(Text(flight.landings.nightCount > 0 ? '${flight.landings.nightCount}' : '', style: const TextStyle(fontSize: 11))),
        DataCell(Text(flight.soloCrossCountry ? 'SOLO XC' : '', style: const TextStyle(fontSize: 11))),
      ],
    );
  }

  DataRow _buildSummaryRow({
    required String label,
    required Color color,
    bool isBold = false,
    required LedgerTotals totals,
  }) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
      color: Colors.white,
    );

    return DataRow(
      color: WidgetStateProperty.all(color),
      cells: [
        // Left Page (1-13)
        DataCell(Text(label, style: style)),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        _summaryCell(totals.instrumentActual, style),
        _summaryCell(totals.instrumentFstd, style),
        _summaryCell(totals.instructorSe, style),
        _summaryCell(totals.instructorMe, style),
        _summaryCell(totals.instructorFstd, style),
        _summaryCell(totals.fstdActual, style),

        // Right Page (14-32)
        _summaryCell(totals.seDayDual, style),
        _summaryCell(totals.seDayPic, style),
        _summaryCell(totals.seDayPicus, style),
        _summaryCell(totals.seDayCopilot, style),
        _summaryCell(totals.seNightDual, style),
        _summaryCell(totals.seNightPic, style),
        _summaryCell(totals.seNightPicus, style),
        _summaryCell(totals.seNightCopilot, style),
        _summaryCell(totals.meDayDual, style),
        _summaryCell(totals.meDayPic, style),
        _summaryCell(totals.meDayPicus, style),
        _summaryCell(totals.meDayCopilot, style),
        _summaryCell(totals.meNightDual, style),
        _summaryCell(totals.meNightPic, style),
        _summaryCell(totals.meNightPicus, style),
        _summaryCell(totals.meNightCopilot, style),
        DataCell(Text(totals.landingsDay > 0 ? '${totals.landingsDay}' : '-', style: style)),
        DataCell(Text(totals.landingsNight > 0 ? '${totals.landingsNight}' : '-', style: style)),
        DataCell(Text('Total: ${TimeUtils.formatMinutesToHhMm(totals.totalFlightTimeMinutes)}', style: style)),
      ],
    );
  }

  DataCell _timeCell(int minutes) {
    return DataCell(
      Text(
        minutes > 0 ? TimeUtils.formatMinutesToHhMm(minutes) : '',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  DataCell _summaryCell(int minutes, TextStyle style) {
    return DataCell(
      Text(
        minutes > 0 ? TimeUtils.formatMinutesToHhMm(minutes) : '-',
        style: style,
      ),
    );
  }
}

