import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/time_utils.dart';
import '../../flights/domain/aircraft_type_summary.dart';
import '../../flights/domain/ledger_totals.dart';

/// Pure PDF generator for the authentic SACAA Career / Renewal Logbook Summary Slip.
///
/// Strictly mirrors the physical slip format used by pilots for SACAA license
/// renewals, revalidations, and rating additions (matching pilot logbook photos).
/// Designed to be printed on standard A4 paper with cutting guides.
class SacaaSummarySlipPdfGenerator {
  const SacaaSummarySlipPdfGenerator._();

  static Future<List<int>> generateSlip({
    required List<AircraftTypeSummary> typeSummaries,
    required LedgerTotals grandTotals,
    required String pilotName,
    required String licenceNumber,
    required DateTime date,
  }) async {
    final doc = pw.Document(
      title: 'SACAA Career Logbook Summary - $pilotName',
      author: pilotName,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.portrait,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'SACAA LOGBOOK SUMMARY SLIP (CAR PART 61)',
                style: const pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Print on standard A4 and cut along dashed border to insert into physical logbook',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 16),

              // The physical cut-out summary slip
              _buildSlipContainer(
                typeSummaries: typeSummaries,
                grandTotals: grandTotals,
                pilotName: pilotName,
                licenceNumber: licenceNumber,
                date: date,
              ),

              pw.SizedBox(height: 24),
              pw.Text(
                'Statutory Note: In accordance with SACAA CAR 61.01.5, pilot logbooks submitted for licence issue, '
                'renewal or revalidation must include an aggregated summary of hours per type and category.',
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColors.grey500,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildSlipContainer({
    required List<AircraftTypeSummary> typeSummaries,
    required LedgerTotals grandTotals,
    required String pilotName,
    required String licenceNumber,
    required DateTime date,
  }) {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey600,
          width: 1,
          style: pw.BorderStyle.dashed,
        ),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Slip Title
          pw.Center(
            child: pw.Text(
              'Career LOGBOOK SUMMARY',
              style: const pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          pw.SizedBox(height: 8),

          // Main 15-Column Table
          _buildSummaryTable(typeSummaries, grandTotals),

          pw.SizedBox(height: 10),

          // Solo Cross Country row
          pw.Center(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'SOLO CROSS COUNTRY: ',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    TimeUtils.formatMinutesToHhMm(
                      grandTotals.soloCrossCountryMinutes,
                    ),
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 12),

          // Sign-off / Authentication box
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Left Column: Name & Licence No
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildFieldRow('NAME', pilotName),
                    pw.SizedBox(height: 6),
                    _buildFieldRow('LICENSE NO.', licenceNumber),
                  ],
                ),
              ),
              pw.SizedBox(width: 32),
              // Right Column: Date & Signature
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildFieldRow('DATE', dateStr),
                    pw.SizedBox(height: 6),
                    _buildFieldRow('SIGNATURE', ''),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFieldRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 75,
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 1),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
              ),
            ),
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryTable(
    List<AircraftTypeSummary> typeSummaries,
    LedgerTotals grandTotals,
  ) {
    const minRows = 6;
    final rowCount = typeSummaries.length < minRows ? minRows : typeSummaries.length;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.0), // TYPE
        1: pw.FlexColumnWidth(1.1), // SE Day Dual
        2: pw.FlexColumnWidth(1.1), // SE Day PIC
        3: pw.FlexColumnWidth(1.1), // SE Night Dual
        4: pw.FlexColumnWidth(1.1), // SE Night PIC
        5: pw.FlexColumnWidth(1.1), // ME Day Dual
        6: pw.FlexColumnWidth(1.1), // ME Day PIC
        7: pw.FlexColumnWidth(1.1), // ME Night Dual
        8: pw.FlexColumnWidth(1.1), // ME Night PIC
        9: pw.FlexColumnWidth(1.1), // FSTD Dual
        10: pw.FlexColumnWidth(1.1), // Inst Actual
        11: pw.FlexColumnWidth(1.1), // Inst FSTD
        12: pw.FlexColumnWidth(1.0), // Inst SE
        13: pw.FlexColumnWidth(1.0), // Inst ME
        14: pw.FlexColumnWidth(1.0), // Inst FSTD
      },
      children: [
        // Level 1 Header (Groups)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _headerCell('TYPE'),
            _groupHeaderCell('SE DAY'),
            _groupHeaderCell('SE DAY'),
            _groupHeaderCell('SE NIGHT'),
            _groupHeaderCell('SE NIGHT'),
            _groupHeaderCell('ME DAY'),
            _groupHeaderCell('ME DAY'),
            _groupHeaderCell('ME NIGHT'),
            _groupHeaderCell('ME NIGHT'),
            _headerCell('FSTD'),
            _groupHeaderCell('INSTRUMENT'),
            _groupHeaderCell('INSTRUMENT'),
            _groupHeaderCell('INSTRUCTOR'),
            _groupHeaderCell('INSTRUCTOR'),
            _groupHeaderCell('INSTRUCTOR'),
          ],
        ),

        // Level 2 Sub-Headers
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _subHeaderCell(''),
            _subHeaderCell('DUAL'),
            _subHeaderCell('PIC'),
            _subHeaderCell('DUAL'),
            _subHeaderCell('PIC'),
            _subHeaderCell('DUAL'),
            _subHeaderCell('PIC'),
            _subHeaderCell('DUAL'),
            _subHeaderCell('PIC'),
            _subHeaderCell('DUAL'),
            _subHeaderCell('ACTUAL'),
            _subHeaderCell('FSTD'),
            _subHeaderCell('SE'),
            _subHeaderCell('ME'),
            _subHeaderCell('FSTD'),
          ],
        ),

        // Data Rows for each Aircraft Type
        for (var i = 0; i < rowCount; i++)
          _buildDataRow(i < typeSummaries.length ? typeSummaries[i] : null),

        // TOTALS Row
        _buildTotalsRow(grandTotals),
      ],
    );
  }

  static pw.TableRow _buildDataRow(AircraftTypeSummary? summary) {
    if (summary == null) {
      return pw.TableRow(
        children: List.generate(
          15,
          (_) => _emptyCell(),
        ),
      );
    }

    final t = summary.totals;
    final sePic = t.seDayPic + t.seDayPicus;
    final seNightPic = t.seNightPic + t.seNightPicus;
    final mePic = t.meDayPic + t.meDayPicus;
    final meNightPic = t.meNightPic + t.meNightPicus;

    return pw.TableRow(
      children: [
        _textCell(summary.aircraftType, isBold: true, align: pw.TextAlign.left),
        _timeCell(t.seDayDual),
        _timeCell(sePic),
        _timeCell(t.seNightDual),
        _timeCell(seNightPic),
        _timeCell(t.meDayDual),
        _timeCell(mePic),
        _timeCell(t.meNightDual),
        _timeCell(meNightPic),
        _timeCell(t.fstdActual),
        _timeCell(t.instrumentActual),
        _timeCell(t.instrumentFstd),
        _timeCell(t.instructorSe),
        _timeCell(t.instructorMe),
        _timeCell(t.instructorFstd),
      ],
    );
  }

  static pw.TableRow _buildTotalsRow(LedgerTotals totals) {
    final sePic = totals.seDayPic + totals.seDayPicus;
    final seNightPic = totals.seNightPic + totals.seNightPicus;
    final mePic = totals.meDayPic + totals.meDayPicus;
    final meNightPic = totals.meNightPic + totals.meNightPicus;

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _textCell('TOTALS', isBold: true, align: pw.TextAlign.left),
        _timeCell(totals.seDayDual, isBold: true),
        _timeCell(sePic, isBold: true),
        _timeCell(totals.seNightDual, isBold: true),
        _timeCell(seNightPic, isBold: true),
        _timeCell(totals.meDayDual, isBold: true),
        _timeCell(mePic, isBold: true),
        _timeCell(totals.meNightDual, isBold: true),
        _timeCell(meNightPic, isBold: true),
        _timeCell(totals.fstdActual, isBold: true),
        _timeCell(totals.instrumentActual, isBold: true),
        _timeCell(totals.instrumentFstd, isBold: true),
        _timeCell(totals.instructorSe, isBold: true),
        _timeCell(totals.instructorMe, isBold: true),
        _timeCell(totals.instructorFstd, isBold: true),
      ],
    );
  }

  static pw.Widget _headerCell(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _groupHeaderCell(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 6,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _subHeaderCell(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 1),
      alignment: pw.Alignment.center,
      child: pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 5.5,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _emptyCell() {
    return pw.Container(
      height: 14,
      alignment: pw.Alignment.center,
      child: pw.Text('', style: const pw.TextStyle(fontSize: 6.5)),
    );
  }

  static pw.Widget _textCell(
    String text, {
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Container(
      height: 14,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
      alignment: align == pw.TextAlign.left
          ? pw.Alignment.centerLeft
          : pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
        maxLines: 1,
      ),
    );
  }

  static pw.Widget _timeCell(int minutes, {bool isBold = false}) {
    final text = minutes > 0 ? TimeUtils.formatMinutesToHhMm(minutes) : '-';
    return pw.Container(
      height: 14,
      padding: const pw.EdgeInsets.symmetric(horizontal: 1),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
