import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../aircraft/domain/aircraft_model.dart';
import '../../flights/domain/flight.dart';
import '../../flights/domain/flight_time.dart';
import '../../flights/domain/instruction_time.dart';
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
            pw.Text('Columns 1 to 13: Operational Particulars, Instrument & Instruction Times', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        pw.SizedBox(height: 4),

        // 13-column Left Grid Table
        pw.Expanded(
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(48), // Col 1: Date
              1: pw.FixedColumnWidth(55), // Col 2: Type
              2: pw.FixedColumnWidth(52), // Col 3: Registration
              3: pw.FixedColumnWidth(82), // Col 4: PIC Name
              4: pw.FlexColumnWidth(1),   // Col 5: Details & Remarks
              5: pw.FixedColumnWidth(45), // Col 6: Navaids
              6: pw.FixedColumnWidth(45), // Col 7: Place
              7: pw.FixedColumnWidth(33), // Col 8: Actual Inst
              8: pw.FixedColumnWidth(33), // Col 9: FSTD Inst
              9: pw.FixedColumnWidth(33), // Col 10: Instructor SE
              10: pw.FixedColumnWidth(33), // Col 11: Instructor ME
              11: pw.FixedColumnWidth(33), // Col 12: Instructor FSTD
              12: pw.FixedColumnWidth(36), // Col 13: FSTD Actual
            },
            children: [
              // Header Row 1
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('DATE', bold: true, height: 16),
                  _cell('TYPE', bold: true),
                  _cell('REGISTRATION', bold: true),
                  _cell('PILOT IN COMMAND', bold: true),
                  _cell('DETAILS OF FLIGHT & REMARKS', bold: true),
                  _cell('INSTRUMENT FLYING', bold: true, colSpan: 4),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell('FLIGHT INSTRUCTOR', bold: true, colSpan: 3),
                  _cell(''),
                  _cell(''),
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
                  _cell('Exercises / Route (5)', fontSize: 6),
                  _cell('Navaids (6)', fontSize: 6),
                  _cell('Place (7)', fontSize: 6),
                  _cell('Actual (8)', fontSize: 6),
                  _cell('FSTD (9)', fontSize: 6),
                  _cell('SE (10)', fontSize: 6),
                  _cell('ME (11)', fontSize: 6),
                  _cell('FSTD (12)', fontSize: 6),
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
                  _cell('BROUGHT FWD', bold: true, colSpan: 5),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _timeCell(page.broughtForward.instrumentActual),
                  _timeCell(page.broughtForward.instrumentFstd),
                  _timeCell(page.broughtForward.instructorSe),
                  _timeCell(page.broughtForward.instructorMe),
                  _timeCell(page.broughtForward.instructorFstd),
                  _timeCell(page.broughtForward.fstdActual),
                ],
              ),

              // Page Totals
              pw.TableRow(
                children: [
                  _cell('THIS PAGE', bold: true, colSpan: 5),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _timeCell(page.pageTotals.instrumentActual),
                  _timeCell(page.pageTotals.instrumentFstd),
                  _timeCell(page.pageTotals.instructorSe),
                  _timeCell(page.pageTotals.instructorMe),
                  _timeCell(page.pageTotals.instructorFstd),
                  _timeCell(page.pageTotals.fstdActual),
                ],
              ),

              // Carried Forward
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('CARRIED FWD', bold: true, colSpan: 5),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _timeCell(page.carriedForward.instrumentActual, bold: true),
                  _timeCell(page.carriedForward.instrumentFstd, bold: true),
                  _timeCell(page.carriedForward.instructorSe, bold: true),
                  _timeCell(page.carriedForward.instructorMe, bold: true),
                  _timeCell(page.carriedForward.instructorFstd, bold: true),
                  _timeCell(page.carriedForward.fstdActual, bold: true),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        // Statutory Footer on Left Page
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Grand total flight time (columns 14 to 29): ${TimeUtils.formatMinutesToHhMm(page.carriedForward.totalSingleEngine + page.carriedForward.totalMultiEngine)} hours',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            ),
            pw.Text(
              'Pilot Signature: ____________________________',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
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

    int instructorSe = 0;
    int instructorMe = 0;
    int instructorFstd = 0;
    for (final it in flight.instructionTimes) {
      switch (it.category) {
        case InstructorCategory.singleEngine:
          instructorSe += it.durationMinutes;
          break;
        case InstructorCategory.multiEngine:
          instructorMe += it.durationMinutes;
          break;
        case InstructorCategory.fstd:
          instructorFstd += it.durationMinutes;
          break;
      }
    }

    return pw.TableRow(
      children: [
        _cell(dateStr, fontSize: 7),
        _cell(flight.aircraftModelId ?? 'AIRCRAFT', fontSize: 7),
        _cell(flight.registration, fontSize: 7, bold: true),
        _cell(flight.picName, fontSize: 7),
        _cell(flight.remarks, fontSize: 6),
        _cell(flight.instrumentTime?.navaids ?? '', fontSize: 6),
        _cell(flight.instrumentTime?.place ?? '', fontSize: 6),
        _timeCell(flight.instrumentTime?.actualMinutes ?? 0),
        _timeCell(flight.instrumentTime?.fstdMinutes ?? 0),
        _timeCell(instructorSe),
        _timeCell(instructorMe),
        _timeCell(instructorFstd),
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
              'SOUTH AFRICAN CIVIL AVIATION AUTHORITY - LOGBOOK (PART 61 APPENDIX A)',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.Text(
              'Page ${page.pageNumber} (Right)',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Columns 14 to 29: Single-Engine & Multi-Engine Operating Functions | Columns 30-32: Landings & Remarks',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Grand Total Flight Time = Sum of Columns 14 to 29',
              style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 4),

        // 19-column Right Grid Table (Columns 14-32)
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
              16: pw.FixedColumnWidth(26), // Col 30: Day Ldg
              17: pw.FixedColumnWidth(26), // Col 31: Night Ldg
              18: pw.FlexColumnWidth(1),   // Col 32: Remarks & Endorsements
            },
            children: [
              // Header Row 1
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('SINGLE-ENGINE AIRCRAFT (14-21)', bold: true, colSpan: 8),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell('MULTI-ENGINE AIRCRAFT (22-29)', bold: true, colSpan: 8),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell('LANDINGS', bold: true, colSpan: 2),
                  _cell(''),
                  _cell('REMARKS / ENDORSEMENTS', bold: true),
                ],
              ),
              // Header Row 2
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('DAY (14-17)', bold: true, colSpan: 4),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell('NIGHT (18-21)', bold: true, colSpan: 4),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell('DAY (22-25)', bold: true, colSpan: 4),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell('NIGHT (26-29)', bold: true, colSpan: 4),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell('Day', fontSize: 6),
                  _cell('Night', fontSize: 6),
                  _cell('Certifications & Signatures (32)', fontSize: 6),
                ],
              ),
              // Header Row 3 (Specific column names)
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('Dual (14)', fontSize: 5.5),
                  _cell('PIC (15)', fontSize: 5.5),
                  _cell('PICUS (16)', fontSize: 5.5),
                  _cell('Copilot (17)', fontSize: 5.5),
                  _cell('Dual (18)', fontSize: 5.5),
                  _cell('PIC (19)', fontSize: 5.5),
                  _cell('PICUS (20)', fontSize: 5.5),
                  _cell('Copilot (21)', fontSize: 5.5),
                  _cell('Dual (22)', fontSize: 5.5),
                  _cell('PIC (23)', fontSize: 5.5),
                  _cell('PICUS (24)', fontSize: 5.5),
                  _cell('Copilot (25)', fontSize: 5.5),
                  _cell('Dual (26)', fontSize: 5.5),
                  _cell('PIC (27)', fontSize: 5.5),
                  _cell('PICUS (28)', fontSize: 5.5),
                  _cell('Copilot (29)', fontSize: 5.5),
                  _cell('30', fontSize: 6),
                  _cell('31', fontSize: 6),
                  _cell('Remarks / Endorsement Box', fontSize: 6),
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
                  _timeCell(page.broughtForward.seDayPic),
                  _timeCell(page.broughtForward.seDayPicus),
                  _timeCell(page.broughtForward.seDayCopilot),
                  _timeCell(page.broughtForward.seNightDual),
                  _timeCell(page.broughtForward.seNightPic),
                  _timeCell(page.broughtForward.seNightPicus),
                  _timeCell(page.broughtForward.seNightCopilot),
                  _timeCell(page.broughtForward.meDayDual),
                  _timeCell(page.broughtForward.meDayPic),
                  _timeCell(page.broughtForward.meDayPicus),
                  _timeCell(page.broughtForward.meDayCopilot),
                  _timeCell(page.broughtForward.meNightDual),
                  _timeCell(page.broughtForward.meNightPic),
                  _timeCell(page.broughtForward.meNightPicus),
                  _timeCell(page.broughtForward.meNightCopilot),
                  _cell(page.broughtForward.landingsDay > 0 ? '${page.broughtForward.landingsDay}' : '-', fontSize: 6),
                  _cell(page.broughtForward.landingsNight > 0 ? '${page.broughtForward.landingsNight}' : '-', fontSize: 6),
                  _cell('TOTAL B/FWD: ${TimeUtils.formatMinutesToHhMm(page.broughtForward.totalFlightTimeMinutes)}', fontSize: 6.5, bold: true),
                ],
              ),

              // Page Totals
              pw.TableRow(
                children: [
                  _timeCell(page.pageTotals.seDayDual),
                  _timeCell(page.pageTotals.seDayPic),
                  _timeCell(page.pageTotals.seDayPicus),
                  _timeCell(page.pageTotals.seDayCopilot),
                  _timeCell(page.pageTotals.seNightDual),
                  _timeCell(page.pageTotals.seNightPic),
                  _timeCell(page.pageTotals.seNightPicus),
                  _timeCell(page.pageTotals.seNightCopilot),
                  _timeCell(page.pageTotals.meDayDual),
                  _timeCell(page.pageTotals.meDayPic),
                  _timeCell(page.pageTotals.meDayPicus),
                  _timeCell(page.pageTotals.meDayCopilot),
                  _timeCell(page.pageTotals.meNightDual),
                  _timeCell(page.pageTotals.meNightPic),
                  _timeCell(page.pageTotals.meNightPicus),
                  _timeCell(page.pageTotals.meNightCopilot),
                  _cell(page.pageTotals.landingsDay > 0 ? '${page.pageTotals.landingsDay}' : '-', fontSize: 6),
                  _cell(page.pageTotals.landingsNight > 0 ? '${page.pageTotals.landingsNight}' : '-', fontSize: 6),
                  _cell('PAGE TOTAL: ${TimeUtils.formatMinutesToHhMm(page.pageTotals.totalFlightTimeMinutes)}', fontSize: 6.5, bold: true),
                ],
              ),

              // Carried Forward
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _timeCell(page.carriedForward.seDayDual, bold: true),
                  _timeCell(page.carriedForward.seDayPic, bold: true),
                  _timeCell(page.carriedForward.seDayPicus, bold: true),
                  _timeCell(page.carriedForward.seDayCopilot, bold: true),
                  _timeCell(page.carriedForward.seNightDual, bold: true),
                  _timeCell(page.carriedForward.seNightPic, bold: true),
                  _timeCell(page.carriedForward.seNightPicus, bold: true),
                  _timeCell(page.carriedForward.seNightCopilot, bold: true),
                  _timeCell(page.carriedForward.meDayDual, bold: true),
                  _timeCell(page.carriedForward.meDayPic, bold: true),
                  _timeCell(page.carriedForward.meDayPicus, bold: true),
                  _timeCell(page.carriedForward.meDayCopilot, bold: true),
                  _timeCell(page.carriedForward.meNightDual, bold: true),
                  _timeCell(page.carriedForward.meNightPic, bold: true),
                  _timeCell(page.carriedForward.meNightPicus, bold: true),
                  _timeCell(page.carriedForward.meNightCopilot, bold: true),
                  _cell(page.carriedForward.landingsDay > 0 ? '${page.carriedForward.landingsDay}' : '-', fontSize: 6, bold: true),
                  _cell(page.carriedForward.landingsNight > 0 ? '${page.carriedForward.landingsNight}' : '-', fontSize: 6, bold: true),
                  _cell('TOTAL C/FWD: ${TimeUtils.formatMinutesToHhMm(page.carriedForward.totalFlightTimeMinutes)}', fontSize: 6.5, bold: true),
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
        children: List.generate(19, (_) => _cell('', height: 17)),
      );
    }

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

    return pw.TableRow(
      children: [
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
        _cell(flight.landings.dayCount > 0 ? '${flight.landings.dayCount}' : '', fontSize: 6),
        _cell(flight.landings.nightCount > 0 ? '${flight.landings.nightCount}' : '', fontSize: 6),
        _cell(flight.soloCrossCountry ? 'SOLO XC' : '', fontSize: 6),
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
