import 'package:flutter_test/flutter_test.dart';
import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/domain/flight_time.dart';
import 'package:aviation_logbook/features/flights/domain/instruction_time.dart';
import 'package:aviation_logbook/features/flights/domain/instrument_time.dart';
import 'package:aviation_logbook/features/flights/domain/ledger_calculator.dart';

void main() {
  const calculator = LedgerCalculator();

  group('AircraftTypeSummary and calculateTotalsByType Tests', () {
    test('Empty flight list produces empty type summaries', () {
      final summaries = calculator.calculateTotalsByType([]);
      expect(summaries, isEmpty);
    });

    test('Groups and accumulates totals accurately by aircraft type', () {
      final date1 = DateTime(2026, 3, 10);
      final date2 = DateTime(2026, 4, 15);
      final date3 = DateTime(2026, 4, 20);

      final flights = [
        Flight(
          id: '1',
          date: date1,
          aircraftModelId: 'C172',
          registration: 'ZS-ABC',
          picName: 'SELF',
          flightTimes: const [
            FlightTime(
              aircraftClass: AircraftClass.singleEngine,
              period: TimePeriod.day,
              role: PilotRole.pic,
              durationMinutes: 60,
            ),
          ],
          instrumentTime: const InstrumentTime(actualMinutes: 20),
          createdAt: date1,
          updatedAt: date1,
        ),
        Flight(
          id: '2',
          date: date2,
          aircraftModelId: 'C172',
          registration: 'ZS-ABC',
          picName: 'SELF',
          flightTimes: const [
            FlightTime(
              aircraftClass: AircraftClass.singleEngine,
              period: TimePeriod.day,
              role: PilotRole.dual,
              durationMinutes: 45,
            ),
          ],
          createdAt: date2,
          updatedAt: date2,
        ),
        Flight(
          id: '3',
          date: date3,
          aircraftModelId: 'BE76',
          registration: 'ZS-XYZ',
          picName: 'INSTRUCTOR',
          flightTimes: const [
            FlightTime(
              aircraftClass: AircraftClass.multiEngine,
              period: TimePeriod.night,
              role: PilotRole.dual,
              durationMinutes: 90,
            ),
          ],
          instructionTimes: const [
            InstructionTime(
              category: InstructorCategory.multiEngine,
              durationMinutes: 90,
            ),
          ],
          createdAt: date3,
          updatedAt: date3,
        ),
      ];

      final summaries = calculator.calculateTotalsByType(flights);

      expect(summaries.length, 2);

      // BE76 is first (alphabetical)
      final be76 = summaries[0];
      expect(be76.aircraftType, 'BE76');
      expect(be76.totals.meNightDual, 90);
      expect(be76.totals.instructorMe, 90);
      expect(be76.dateLastFlown, date3);

      // C172 is second
      final c172 = summaries[1];
      expect(c172.aircraftType, 'C172');
      expect(c172.totals.seDayPic, 60);
      expect(c172.totals.seDayDual, 45);
      expect(c172.totals.totalSingleEngineDay, 105);
      expect(c172.totals.instrumentActual, 20);
      expect(c172.dateLastFlown, date2);
    });

    test('Defaults unassigned aircraftModelId to AIRCRAFT', () {
      final date = DateTime(2026, 5, 1);
      final flights = [
        Flight(
          id: '1',
          date: date,
          aircraftModelId: null,
          registration: 'ZS-TST',
          picName: 'SELF',
          flightTimes: const [
            FlightTime(
              aircraftClass: AircraftClass.singleEngine,
              period: TimePeriod.day,
              role: PilotRole.pic,
              durationMinutes: 30,
            ),
          ],
          createdAt: date,
          updatedAt: date,
        ),
      ];

      final summaries = calculator.calculateTotalsByType(flights);
      expect(summaries.length, 1);
      expect(summaries.first.aircraftType, 'AIRCRAFT');
      expect(summaries.first.totals.seDayPic, 30);
    });
  });
}
