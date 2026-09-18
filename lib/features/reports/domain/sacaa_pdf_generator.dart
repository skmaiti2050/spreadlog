import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../aircraft/domain/aircraft_model.dart';
import '../../flights/domain/flight.dart';
import '../../flights/domain/flight_time.dart';
import '../../flights/domain/ledger_page.dart';
import '../../flights/domain/ledger_totals.dart';
import '../../../core/utils/time_utils.dart';

/// Pure PDF generator implementing statutory SACAA CAR Part 61 Appendix A layout.
/// Produces a landscape multi-page document with:
/// - Left Page: Columns 1 to 13
/// - Right Page: Columns 14 to 32
/// - Bottom totals: Brought Forward, This Page, Carried Forward
class SacaaPdfGenerator {
  static Future<List<int>> generateDocument({
    required List<LedgerPage> pages,
    required String pilotName,
    required String licenceNumber,
  }) async {
    final doc = pw.Document(
      title: 'SACAA Pilot Logbook - $pilotName',
      author: pilotName,
    );

    final pagesToRender = pages.isEmpty
        ? [
            const LedgerPage(
              pageNumber: 1,
              entries: [],
              broughtForward: LedgerTotals.zero,
              pageTotals: LedgerTotals.zero,
              carriedForward: LedgerTotals.zero,
            ),
          ]
        : pages;

    for (final page in pagesToRender) {
      // 1. Left Page (Columns 1-13)
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return _buildLeftPage(page, pilotName, licenceNumber);
          },
        ),
      );

      // 2. Right Page (Columns 14-32)
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return _buildRightPage(page);
          },
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _buildLeftPage(
    LedgerPage page,
    String pilotName,
    String licenceNumber,
  ) {
    const rowCount = 14;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'SOUTH AFRICAN CIVIL AVIATION AUTHORITY - LOGBOOK (PART 61 APPENDIX A)',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.Text(
              'Page ${page.pageNumber} (Left)',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Pilot: $pilotName    Licence: $licenceNumber', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Entries 1 to 13: Operational Details & Single/Multi Engine Times', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        pw.SizedBox(height: 4),

        // 13-column Left Grid Table
        pw.Expanded(
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(48), // Col 1: Date
              1: pw.FixedColumnWidth(60), // Col 2: Type
              2: pw.FixedColumnWidth(52), // Col 3: Registration
              3: pw.FixedColumnWidth(90), // Col 4: PIC Name
              4: pw.FixedColumnWidth(45), // Col 5: Dep Place
              5: pw.FixedColumnWidth(35), // Col 6: Dep Time
              6: pw.FixedColumnWidth(45), // Col 7: Arr Place
              7: pw.FixedColumnWidth(35), // Col 8: Arr Time
              8: pw.FixedColumnWidth(42), // Col 9: SE Day
              9: pw.FixedColumnWidth(42), // Col 10: SE Night
              10: pw.FixedColumnWidth(42), // Col 11: ME Day
              11: pw.FixedColumnWidth(42), // Col 12: ME Night
              12: pw.FixedColumnWidth(46), // Col 13: FSTD
            },
            children: [
              // Header Row 1
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('DATE', bold: true, height: 16),
                  _cell('AIRCRAFT TYPE', bold: true),
                  _cell('REGISTRATION', bold: true),
                  _cell('COMMANDER / PIC', bold: true),
                  _cell('DEPARTURE', bold: true, colSpan: 2),
                  _cell('', bold: true),
                  _cell('ARRIVAL', bold: true, colSpan: 2),
                  _cell('', bold: true),
                  _cell('SINGLE ENGINE', bold: true, colSpan: 2),
                  _cell('', bold: true),
                  _cell('MULTI ENGINE', bold: true, colSpan: 2),
                  _cell('', bold: true),
                  _cell('FSTD', bold: true),
                ],
              ),
              // Header Row 2 (Columns 1-13)
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('1', fontSize: 6),
                  _cell('2', fontSize: 6),
                  _cell('3', fontSize: 6),
                  _cell('4', fontSize: 6),
                  _cell('Place (5)', fontSize: 6),
                  _cell('UTC (6)', fontSize: 6),
                  _cell('Place (7)', fontSize: 6),
                  _cell('UTC (8)', fontSize: 6),
                  _cell('Day (9)', fontSize: 6),
                  _cell('Night (10)', fontSize: 6),
                  _cell('Day (11)', fontSize: 6),
                  _cell('Night (12)', fontSize: 6),
                  _cell('Actual (13)', fontSize: 6),
                ],
              ),

              // 14 Flight Rows
              for (int i = 0; i < rowCount; i++)
                _buildLeftFlightRow(i < page.entries.length ? page.entries[i] : null),

              // Brought Forward
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _cell('BROUGHT FWD', bold: true, colSpan: 8),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _timeCell(page.broughtForward.totalSingleEngineDay),
                  _timeCell(page.broughtForward.totalSingleEngineNight),
                  _timeCell(page.broughtForward.totalMultiEngineDay),
                  _timeCell(page.broughtForward.totalMultiEngineNight),
                  _timeCell(page.broughtForward.fstdActual),
                ],
              ),

              // Page Totals
              pw.TableRow(
                children: [
                  _cell('THIS PAGE', bold: true, colSpan: 8),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _timeCell(page.pageTotals.totalSingleEngineDay),
                  _timeCell(page.pageTotals.totalSingleEngineNight),
                  _timeCell(page.pageTotals.totalMultiEngineDay),
                  _timeCell(page.pageTotals.totalMultiEngineNight),
                  _timeCell(page.pageTotals.fstdActual),
                ],
              ),

              // Carried Forward
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('CARRIED FWD', bold: true, colSpan: 8),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _timeCell(page.carriedForward.totalSingleEngineDay, bold: true),
                  _timeCell(page.carriedForward.totalSingleEngineNight, bold: true),
                  _timeCell(page.carriedForward.totalMultiEngineDay, bold: true),
                  _timeCell(page.carriedForward.totalMultiEngineNight, bold: true),
                  _timeCell(page.carriedForward.fstdActual, bold: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildLeftFlightRow(Flight? flight) {
    if (flight == null) {
      return pw.TableRow(
        children: List.generate(13, (_) => _cell('', height: 17)),
      );
    }

    final dateStr = '${flight.date.year.toString().padLeft(4, '0')}-${flight.date.month.toString().padLeft(2, '0')}-${flight.date.day.toString().padLeft(2, '0')}';

    final seDay = flight.flightTimes
        .where((ft) => ft.aircraftClass == AircraftClass.singleEngine && ft.period == TimePeriod.day)
        .fold(0, (s, ft) => s + ft.durationMinutes);
    final seNight = flight.flightTimes
        .where((ft) => ft.aircraftClass == AircraftClass.singleEngine && ft.period == TimePeriod.night)
        .fold(0, (s, ft) => s + ft.durationMinutes);
    final meDay = flight.flightTimes
        .where((ft) => ft.aircraftClass == AircraftClass.multiEngine && ft.period == TimePeriod.day)
        .fold(0, (s, ft) => s + ft.durationMinutes);
    final meNight = flight.flightTimes
        .where((ft) => ft.aircraftClass == AircraftClass.multiEngine && ft.period == TimePeriod.night)
        .fold(0, (s, ft) => s + ft.durationMinutes);

    return pw.TableRow(
      children: [
        _cell(dateStr, fontSize: 7),
        _cell(flight.aircraftModelId ?? 'AIRCRAFT', fontSize: 7),
        _cell(flight.registration, fontSize: 7, bold: true),
        _cell(flight.picName, fontSize: 7),
        _cell('-', fontSize: 7),
        _cell('-', fontSize: 7),
        _cell('-', fontSize: 7),
        _cell('-', fontSize: 7),
        _timeCell(seDay),
        _timeCell(seNight),
        _timeCell(meDay),
        _timeCell(meNight),
        _timeCell(flight.fstdActualMinutes),
      ],
    );
  }

  static pw.Widget _buildRightPage(LedgerPage page) {
    const rowCount = 14;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'OPERATIONAL CONDITION & PILOT FUNCTION TIMES (COLUMNS 14 TO 32)',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.Text(
              'Page ${page.pageNumber} (Right)',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ],
        ),
        pw.SizedBox(height: 6),

        // Right Grid Table
        pw.Expanded(
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(34),
              1: pw.FixedColumnWidth(34),
              2: pw.FixedColumnWidth(34),
              3: pw.FixedColumnWidth(34),
              4: pw.FixedColumnWidth(34),
              5: pw.FixedColumnWidth(34),
              6: pw.FixedColumnWidth(34),
              7: pw.FixedColumnWidth(34),
              8: pw.FixedColumnWidth(34),
              9: pw.FixedColumnWidth(34),
              10: pw.FixedColumnWidth(34),
              11: pw.FixedColumnWidth(34),
              12: pw.FixedColumnWidth(34),
              13: pw.FixedColumnWidth(34),
              14: pw.FixedColumnWidth(34),
              15: pw.FixedColumnWidth(34),
              16: pw.FixedColumnWidth(40),
              17: pw.FixedColumnWidth(40),
              18: pw.FixedColumnWidth(32),
              19: pw.FlexColumnWidth(1),
            },
            children: [
              // Header Row 1
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('SE DUAL', bold: true, colSpan: 2),
                  _cell(''),
                  _cell('SE PIC', bold: true, colSpan: 2),
                  _cell(''),
                  _cell('SE PICUS', bold: true, colSpan: 2),
                  _cell(''),
                  _cell('SE COPILOT', bold: true, colSpan: 2),
                  _cell(''),
                  _cell('ME DUAL', bold: true, colSpan: 2),
                  _cell(''),
                  _cell('ME PIC', bold: true, colSpan: 2),
                  _cell(''),
                  _cell('ME PICUS', bold: true, colSpan: 2),
                  _cell(''),
                  _cell('ME COPILOT', bold: true, colSpan: 2),
                  _cell(''),
                  _cell('INSTRUMENT', bold: true, colSpan: 2),
                  _cell(''),
                  _cell('LDG', bold: true),
                  _cell('REMARKS & ENDORSEMENTS', bold: true),
                ],
              ),
              // Header Row 2 (Columns 14-32)
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('14', fontSize: 6),
                  _cell('15', fontSize: 6),
                  _cell('16', fontSize: 6),
                  _cell('17', fontSize: 6),
                  _cell('18', fontSize: 6),
                  _cell('19', fontSize: 6),
                  _cell('20', fontSize: 6),
                  _cell('21', fontSize: 6),
                  _cell('22', fontSize: 6),
                  _cell('23', fontSize: 6),
                  _cell('24', fontSize: 6),
                  _cell('25', fontSize: 6),
                  _cell('26', fontSize: 6),
                  _cell('27', fontSize: 6),
                  _cell('28', fontSize: 6),
                  _cell('29', fontSize: 6),
                  _cell('Act', fontSize: 6),
                  _cell('Sim', fontSize: 6),
                  _cell('D/N', fontSize: 6),
                  _cell('Remarks / Endorsement Box (32)', fontSize: 6),
                ],
              ),

              // 14 Flight Rows
              for (int i = 0; i < rowCount; i++)
                _buildRightFlightRow(i < page.entries.length ? page.entries[i] : null),

              // Brought Forward
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _timeCell(page.broughtForward.seDayDual),
                  _timeCell(page.broughtForward.seNightDual),
                  _timeCell(page.broughtForward.seDayPic),
                  _timeCell(page.broughtForward.seNightPic),
                  _timeCell(page.broughtForward.seDayPicus),
                  _timeCell(page.broughtForward.seNightPicus),
                  _timeCell(page.broughtForward.seDayCopilot),
                  _timeCell(page.broughtForward.seNightCopilot),
                  _timeCell(page.broughtForward.meDayDual),
                  _timeCell(page.broughtForward.meNightDual),
                  _timeCell(page.broughtForward.meDayPic),
                  _timeCell(page.broughtForward.meNightPic),
                  _timeCell(page.broughtForward.meDayPicus),
                  _timeCell(page.broughtForward.meNightPicus),
                  _timeCell(page.broughtForward.meDayCopilot),
                  _timeCell(page.broughtForward.meNightCopilot),
                  _timeCell(page.broughtForward.instrumentActual),
                  _timeCell(page.broughtForward.instrumentFstd),
                  _cell('${page.broughtForward.landingsDay}/${page.broughtForward.landingsNight}', fontSize: 6),
                  _cell('TOTAL TIME B/FWD: ${TimeUtils.formatMinutesToHhMm(page.broughtForward.totalFlightTimeMinutes)}', fontSize: 7, bold: true),
                ],
              ),

              // Page Totals
              pw.TableRow(
                children: [
                  _timeCell(page.pageTotals.seDayDual),
                  _timeCell(page.pageTotals.seNightDual),
                  _timeCell(page.pageTotals.seDayPic),
                  _timeCell(page.pageTotals.seNightPic),
                  _timeCell(page.pageTotals.seDayPicus),
                  _timeCell(page.pageTotals.seNightPicus),
                  _timeCell(page.pageTotals.seDayCopilot),
                  _timeCell(page.pageTotals.seNightCopilot),
                  _timeCell(page.pageTotals.meDayDual),
                  _timeCell(page.pageTotals.meNightDual),
                  _timeCell(page.pageTotals.meDayPic),
                  _timeCell(page.pageTotals.meNightPic),
                  _timeCell(page.pageTotals.meDayPicus),
                  _timeCell(page.pageTotals.meNightPicus),
                  _timeCell(page.pageTotals.meDayCopilot),
                  _timeCell(page.pageTotals.meNightCopilot),
                  _timeCell(page.pageTotals.instrumentActual),
                  _timeCell(page.pageTotals.instrumentFstd),
                  _cell('${page.pageTotals.landingsDay}/${page.pageTotals.landingsNight}', fontSize: 6),
                  _cell('PAGE TOTAL TIME: ${TimeUtils.formatMinutesToHhMm(page.pageTotals.totalFlightTimeMinutes)}', fontSize: 7, bold: true),
                ],
              ),

              // Carried Forward
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _timeCell(page.carriedForward.seDayDual, bold: true),
                  _timeCell(page.carriedForward.seNightDual, bold: true),
                  _timeCell(page.carriedForward.seDayPic, bold: true),
                  _timeCell(page.carriedForward.seNightPic, bold: true),
                  _timeCell(page.carriedForward.seDayPicus, bold: true),
                  _timeCell(page.carriedForward.seNightPicus, bold: true),
                  _timeCell(page.carriedForward.seDayCopilot, bold: true),
                  _timeCell(page.carriedForward.seNightCopilot, bold: true),
                  _timeCell(page.carriedForward.meDayDual, bold: true),
                  _timeCell(page.carriedForward.meNightDual, bold: true),
                  _timeCell(page.carriedForward.meDayPic, bold: true),
                  _timeCell(page.carriedForward.meNightPic, bold: true),
                  _timeCell(page.carriedForward.meDayPicus, bold: true),
                  _timeCell(page.carriedForward.meNightPicus, bold: true),
                  _timeCell(page.carriedForward.meDayCopilot, bold: true),
                  _timeCell(page.carriedForward.meNightCopilot, bold: true),
                  _timeCell(page.carriedForward.instrumentActual, bold: true),
                  _timeCell(page.carriedForward.instrumentFstd, bold: true),
                  _cell('${page.carriedForward.landingsDay}/${page.carriedForward.landingsNight}', fontSize: 6, bold: true),
                  _cell('TOTAL TIME C/FWD: ${TimeUtils.formatMinutesToHhMm(page.carriedForward.totalFlightTimeMinutes)}', fontSize: 7, bold: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildRightFlightRow(Flight? flight) {
    if (flight == null) {
      return pw.TableRow(
        children: List.generate(20, (_) => _cell('', height: 17)),
      );
    }

    int seDayDual = 0, seNightDual = 0, seDayPic = 0, seNightPic = 0;
    int seDayPicus = 0, seNightPicus = 0, seDayCopilot = 0, seNightCopilot = 0;
    int meDayDual = 0, meNightDual = 0, meDayPic = 0, meNightPic = 0;
    int meDayPicus = 0, meNightPicus = 0, meDayCopilot = 0, meNightCopilot = 0;

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

    return pw.TableRow(
      children: [
        _timeCell(seDayDual),
        _timeCell(seNightDual),
        _timeCell(seDayPic),
        _timeCell(seNightPic),
        _timeCell(seDayPicus),
        _timeCell(seNightPicus),
        _timeCell(seDayCopilot),
        _timeCell(seNightCopilot),
        _timeCell(meDayDual),
        _timeCell(meNightDual),
        _timeCell(meDayPic),
        _timeCell(meNightPic),
        _timeCell(meDayPicus),
        _timeCell(meNightPicus),
        _timeCell(meDayCopilot),
        _timeCell(meNightCopilot),
        _timeCell(flight.instrumentTime?.actualMinutes ?? 0),
        _timeCell(flight.instrumentTime?.fstdMinutes ?? 0),
        _cell('${flight.landings.dayCount}/${flight.landings.nightCount}', fontSize: 6),
        _cell(flight.remarks, fontSize: 6),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    double fontSize = 7,
    double height = 15,
    int colSpan = 1,
  }) {
    return pw.Container(
      height: height,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: pw.Text(
        text,
        maxLines: 1,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _timeCell(int minutes, {bool bold = false}) {
    final text = minutes > 0 ? TimeUtils.formatMinutesToHhMm(minutes) : '';
    return _cell(text, bold: bold, fontSize: 6.5);
  }
}
