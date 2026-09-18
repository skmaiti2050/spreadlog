import 'package:flutter/material.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../aircraft/domain/aircraft_model.dart';
import '../../domain/flight.dart';
import '../../domain/flight_time.dart';
import '../../domain/ledger_page.dart';

/// Clean, high-density physical logbook spread screen.
/// Renders the exact 14 flight rows, Brought Forward, Page Totals, and Carried Forward.
class PhysicalLogbookScreen extends StatefulWidget {
  final List<LedgerPage> pages;

  const PhysicalLogbookScreen({
    super.key,
    required this.pages,
  });

  @override
  State<PhysicalLogbookScreen> createState() => _PhysicalLogbookScreenState();
}

class _PhysicalLogbookScreenState extends State<PhysicalLogbookScreen> {
  int _currentPageIndex = 0;

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
        title: Text('SACAA Appendix A — Page ${page.pageNumber} of ${widget.pages.length}'),
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
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
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
        DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('REG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('PIC / CREW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE DAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE NIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME DAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME NIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('FSTD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE DUAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE PIC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE PICUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('SE COPILOT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME DUAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME PIC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME PICUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('ME COPILOT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('INST ACT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('INST SIM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('LDGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(label: Text('REMARKS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
      ],
      rows: [
        // 14 standard logbook entries
        for (int i = 0; i < rowCount; i++)
          _buildDataRow(i < page.entries.length ? page.entries[i] : null),

        // Brought Forward
        _buildSummaryRow(
          label: 'BROUGHT FORWARD',
          color: Colors.blueGrey.shade800.withValues(alpha: 0.5),
          seDay: page.broughtForward.totalSingleEngineDay,
          seNight: page.broughtForward.totalSingleEngineNight,
          meDay: page.broughtForward.totalMultiEngineDay,
          meNight: page.broughtForward.totalMultiEngineNight,
          fstd: page.broughtForward.fstdActual,
          seDual: page.broughtForward.seDayDual + page.broughtForward.seNightDual,
          sePic: page.broughtForward.seDayPic + page.broughtForward.seNightPic,
          sePicus: page.broughtForward.seDayPicus + page.broughtForward.seNightPicus,
          seCopilot: page.broughtForward.seDayCopilot + page.broughtForward.seNightCopilot,
          meDual: page.broughtForward.meDayDual + page.broughtForward.meNightDual,
          mePic: page.broughtForward.meDayPic + page.broughtForward.meNightPic,
          mePicus: page.broughtForward.meDayPicus + page.broughtForward.meNightPicus,
          meCopilot: page.broughtForward.meDayCopilot + page.broughtForward.meNightCopilot,
          instAct: page.broughtForward.instrumentActual,
          instSim: page.broughtForward.instrumentFstd,
          landings: '${page.broughtForward.landingsDay}/${page.broughtForward.landingsNight}',
          remarks: 'Total: ${TimeUtils.formatMinutesToHhMm(page.broughtForward.totalFlightTimeMinutes)}',
        ),

        // Page Totals
        _buildSummaryRow(
          label: 'THIS PAGE TOTAL',
          color: Colors.blueGrey.shade900,
          seDay: page.pageTotals.totalSingleEngineDay,
          seNight: page.pageTotals.totalSingleEngineNight,
          meDay: page.pageTotals.totalMultiEngineDay,
          meNight: page.pageTotals.totalMultiEngineNight,
          fstd: page.pageTotals.fstdActual,
          seDual: page.pageTotals.seDayDual + page.pageTotals.seNightDual,
          sePic: page.pageTotals.seDayPic + page.pageTotals.seNightPic,
          sePicus: page.pageTotals.seDayPicus + page.pageTotals.seNightPicus,
          seCopilot: page.pageTotals.seDayCopilot + page.pageTotals.seNightCopilot,
          meDual: page.pageTotals.meDayDual + page.pageTotals.meNightDual,
          mePic: page.pageTotals.meDayPic + page.pageTotals.meNightPic,
          mePicus: page.pageTotals.meDayPicus + page.pageTotals.meNightPicus,
          meCopilot: page.pageTotals.meDayCopilot + page.pageTotals.meNightCopilot,
          instAct: page.pageTotals.instrumentActual,
          instSim: page.pageTotals.instrumentFstd,
          landings: '${page.pageTotals.landingsDay}/${page.pageTotals.landingsNight}',
          remarks: 'Page: ${TimeUtils.formatMinutesToHhMm(page.pageTotals.totalFlightTimeMinutes)}',
        ),

        // Carried Forward
        _buildSummaryRow(
          label: 'CARRIED FORWARD',
          color: Colors.indigo.shade900.withValues(alpha: 0.6),
          isBold: true,
          seDay: page.carriedForward.totalSingleEngineDay,
          seNight: page.carriedForward.totalSingleEngineNight,
          meDay: page.carriedForward.totalMultiEngineDay,
          meNight: page.carriedForward.totalMultiEngineNight,
          fstd: page.carriedForward.fstdActual,
          seDual: page.carriedForward.seDayDual + page.carriedForward.seNightDual,
          sePic: page.carriedForward.seDayPic + page.carriedForward.seNightPic,
          sePicus: page.carriedForward.seDayPicus + page.carriedForward.seNightPicus,
          seCopilot: page.carriedForward.seDayCopilot + page.carriedForward.seNightCopilot,
          meDual: page.carriedForward.meDayDual + page.carriedForward.meNightDual,
          mePic: page.carriedForward.meDayPic + page.carriedForward.meNightPic,
          mePicus: page.carriedForward.meDayPicus + page.carriedForward.meNightPicus,
          meCopilot: page.carriedForward.meDayCopilot + page.carriedForward.meNightCopilot,
          instAct: page.carriedForward.instrumentActual,
          instSim: page.carriedForward.instrumentFstd,
          landings: '${page.carriedForward.landingsDay}/${page.carriedForward.landingsNight}',
          remarks: 'Total: ${TimeUtils.formatMinutesToHhMm(page.carriedForward.totalFlightTimeMinutes)}',
        ),
      ],
    );
  }

  DataRow _buildDataRow(Flight? flight) {
    if (flight == null) {
      return DataRow(
        cells: List.generate(21, (_) => const DataCell(Text(''))),
      );
    }

    final dateStr = '${flight.date.day.toString().padLeft(2, '0')}/${flight.date.month.toString().padLeft(2, '0')}';
    final seDay = flight.flightTimes
        .where((ft) => ft.aircraftClass == AircraftClass.singleEngine && ft.period == TimePeriod.day)
        .fold<int>(0, (s, ft) => s + ft.durationMinutes);
    final seNight = flight.flightTimes
        .where((ft) => ft.aircraftClass == AircraftClass.singleEngine && ft.period == TimePeriod.night)
        .fold<int>(0, (s, ft) => s + ft.durationMinutes);
    final meDay = flight.flightTimes
        .where((ft) => ft.aircraftClass == AircraftClass.multiEngine && ft.period == TimePeriod.day)
        .fold<int>(0, (s, ft) => s + ft.durationMinutes);
    final meNight = flight.flightTimes
        .where((ft) => ft.aircraftClass == AircraftClass.multiEngine && ft.period == TimePeriod.night)
        .fold<int>(0, (s, ft) => s + ft.durationMinutes);

    int seDual = 0, sePic = 0, sePicus = 0, seCopilot = 0;
    int meDual = 0, mePic = 0, mePicus = 0, meCopilot = 0;

    for (final ft in flight.flightTimes) {
      if (ft.aircraftClass == AircraftClass.singleEngine) {
        switch (ft.role) {
          case PilotRole.dual: seDual += ft.durationMinutes; break;
          case PilotRole.pic: sePic += ft.durationMinutes; break;
          case PilotRole.picus: sePicus += ft.durationMinutes; break;
          case PilotRole.copilot: seCopilot += ft.durationMinutes; break;
        }
      } else {
        switch (ft.role) {
          case PilotRole.dual: meDual += ft.durationMinutes; break;
          case PilotRole.pic: mePic += ft.durationMinutes; break;
          case PilotRole.picus: mePicus += ft.durationMinutes; break;
          case PilotRole.copilot: meCopilot += ft.durationMinutes; break;
        }
      }
    }

    return DataRow(
      cells: [
        DataCell(Text(dateStr, style: const TextStyle(fontSize: 11))),
        DataCell(Text(flight.aircraftModelId ?? 'AIRCRAFT', style: const TextStyle(fontSize: 11))),
        DataCell(Text(flight.registration, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataCell(Text(flight.picName, style: const TextStyle(fontSize: 11))),
        _timeCell(seDay),
        _timeCell(seNight),
        _timeCell(meDay),
        _timeCell(meNight),
        _timeCell(flight.fstdActualMinutes),
        _timeCell(seDual),
        _timeCell(sePic),
        _timeCell(sePicus),
        _timeCell(seCopilot),
        _timeCell(meDual),
        _timeCell(mePic),
        _timeCell(mePicus),
        _timeCell(meCopilot),
        _timeCell(flight.instrumentTime?.actualMinutes ?? 0),
        _timeCell(flight.instrumentTime?.fstdMinutes ?? 0),
        DataCell(Text('${flight.landings.dayCount}/${flight.landings.nightCount}', style: const TextStyle(fontSize: 11))),
        DataCell(Text(flight.remarks, style: const TextStyle(fontSize: 11))),
      ],
    );
  }

  DataRow _buildSummaryRow({
    required String label,
    required Color color,
    bool isBold = false,
    required int seDay,
    required int seNight,
    required int meDay,
    required int meNight,
    required int fstd,
    required int seDual,
    required int sePic,
    required int sePicus,
    required int seCopilot,
    required int meDual,
    required int mePic,
    required int mePicus,
    required int meCopilot,
    required int instAct,
    required int instSim,
    required String landings,
    required String remarks,
  }) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
      color: Colors.white,
    );

    return DataRow(
      color: WidgetStateProperty.all(color),
      cells: [
        DataCell(Text(label, style: style)),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        _summaryCell(seDay, style),
        _summaryCell(seNight, style),
        _summaryCell(meDay, style),
        _summaryCell(meNight, style),
        _summaryCell(fstd, style),
        _summaryCell(seDual, style),
        _summaryCell(sePic, style),
        _summaryCell(sePicus, style),
        _summaryCell(seCopilot, style),
        _summaryCell(meDual, style),
        _summaryCell(mePic, style),
        _summaryCell(mePicus, style),
        _summaryCell(meCopilot, style),
        _summaryCell(instAct, style),
        _summaryCell(instSim, style),
        DataCell(Text(landings, style: style)),
        DataCell(Text(remarks, style: style)),
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

