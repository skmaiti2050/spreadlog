import 'package:flutter_test/flutter_test.dart';
import 'package:aviation_logbook/features/flights/domain/aircraft_type_summary.dart';
import 'package:aviation_logbook/features/flights/domain/ledger_totals.dart';
import 'package:aviation_logbook/features/reports/domain/sacaa_summary_slip_generator.dart';

void main() {
  group('SacaaSummarySlipPdfGenerator Tests', () {
    test('Generates valid non-empty PDF byte stream with %PDF header', () async {
      final typeSummaries = [
        const AircraftTypeSummary(
          aircraftType: 'C172',
          totals: LedgerTotals(
            seDayDual: 120,
            seDayPic: 300,
            seNightDual: 60,
            seNightPic: 60,
            instrumentActual: 45,
            soloCrossCountryMinutes: 180,
          ),
        ),
        const AircraftTypeSummary(
          aircraftType: 'BE76',
          totals: LedgerTotals(
            meDayDual: 90,
            meDayPic: 120,
            meNightDual: 60,
            meNightPic: 30,
            instructorMe: 90,
          ),
        ),
      ];

      const grandTotals = LedgerTotals(
        seDayDual: 120,
        seDayPic: 300,
        seNightDual: 60,
        seNightPic: 60,
        meDayDual: 90,
        meDayPic: 120,
        meNightDual: 60,
        meNightPic: 30,
        instrumentActual: 45,
        instructorMe: 90,
        soloCrossCountryMinutes: 180,
      );

      final pdfBytes = await SacaaSummarySlipPdfGenerator.generateSlip(
        typeSummaries: typeSummaries,
        grandTotals: grandTotals,
        pilotName: 'CAPT J. DOE',
        licenceNumber: 'ZA-987654',
        date: DateTime(2026, 9, 19),
      );

      expect(pdfBytes, isNotEmpty);
      // Valid PDF files always start with %PDF- (bytes 0x25, 0x50, 0x44, 0x46, 0x2D)
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });

    test('Generates valid PDF even with empty summaries', () async {
      final pdfBytes = await SacaaSummarySlipPdfGenerator.generateSlip(
        typeSummaries: [],
        grandTotals: LedgerTotals.zero,
        pilotName: 'STUDENT PILOT',
        licenceNumber: 'ZA-000000',
        date: DateTime(2026, 9, 19),
      );

      expect(pdfBytes, isNotEmpty);
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });
  });
}

