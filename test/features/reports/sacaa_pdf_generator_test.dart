import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/domain/flight_time.dart';
import 'package:aviation_logbook/features/flights/domain/landings.dart';
import 'package:aviation_logbook/features/flights/domain/ledger_calculator.dart';
import 'package:aviation_logbook/features/reports/domain/sacaa_pdf_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = LedgerCalculator();

  group('SacaaPdfGenerator Tests', () {
    test('Generates valid PDF byte stream with %PDF header', () async {
      final now = DateTime(2026, 9, 18);
      final flights = [
        Flight(
          id: 'f1',
          date: now,
          registration: 'ZS-EXT',
          picName: 'SELF',
          remarks: 'Local training flight',
          flightTimes: const [
            FlightTime(
              aircraftClass: AircraftClass.singleEngine,
              period: TimePeriod.day,
              role: PilotRole.pic,
              durationMinutes: 90,
            ),
          ],
          landings: const Landings(dayCount: 2),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final pages = calculator.paginateLedger(flights);
      final pdfBytes = await SacaaPdfGenerator.generateDocument(
        pages: pages,
        pilotName: 'CAPT. TEST PILOT',
        licenceNumber: 'ZA-987654',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));

      // PDF files always begin with magic bytes '%PDF-'
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
    });
  });
}

