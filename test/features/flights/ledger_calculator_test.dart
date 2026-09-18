import 'package:aviation_logbook/core/utils/time_utils.dart';
import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/domain/flight_time.dart';
import 'package:aviation_logbook/features/flights/domain/instruction_time.dart';
import 'package:aviation_logbook/features/flights/domain/instrument_time.dart';
import 'package:aviation_logbook/features/flights/domain/landings.dart';
import 'package:aviation_logbook/features/flights/domain/ledger_calculator.dart';
import 'package:aviation_logbook/features/flights/domain/ledger_totals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = LedgerCalculator();

  Flight createSampleFlight({
    required String id,
    required DateTime date,
    List<FlightTime> flightTimes = const [],
    InstrumentTime? instrumentTime,
    List<InstructionTime> instructionTimes = const [],
    Landings landings = const Landings(),
    bool soloCrossCountry = false,
    int fstdActualMinutes = 0,
  }) {
    return Flight(
      id: id,
      date: date,
      registration: 'ZS-ABC',
      picName: 'SELF',
      remarks: 'Local training',
      soloCrossCountry: soloCrossCountry,
      fstdActualMinutes: fstdActualMinutes,
      flightTimes: flightTimes,
      instrumentTime: instrumentTime,
      instructionTimes: instructionTimes,
      landings: landings,
      createdAt: date,
      updatedAt: date,
    );
  }

  group('LedgerCalculator Unit Tests', () {
    test('Empty flight list yields zero totals', () {
      final totals = calculator.calculateTotals([]);
      expect(totals, LedgerTotals.zero);
      expect(totals.totalFlightTimeMinutes, 0);
      expect(totals.totalLandings, 0);
    });

    test('Single flight calculates correctly across categories', () {
      final flight = createSampleFlight(
        id: 'f1',
        date: DateTime(2026, 3, 1),
        flightTimes: [
          const FlightTime(
            aircraftClass: AircraftClass.singleEngine,
            period: TimePeriod.day,
            role: PilotRole.pic,
            durationMinutes: 90, // 01:30
          ),
          const FlightTime(
            aircraftClass: AircraftClass.singleEngine,
            period: TimePeriod.night,
            role: PilotRole.dual,
            durationMinutes: 45, // 00:45
          ),
        ],
        instrumentTime: const InstrumentTime(
          actualMinutes: 30,
          fstdMinutes: 20,
          navaids: 'VOR/ILS',
          place: 'FALA',
        ),
        instructionTimes: [
          const InstructionTime(
            category: InstructorCategory.singleEngine,
            durationMinutes: 90,
          ),
        ],
        landings: const Landings(dayCount: 2, nightCount: 1),
        soloCrossCountry: true,
      );

      final totals = calculator.calculateFlightTotals(flight);

      expect(totals.seDayPic, 90);
      expect(totals.seNightDual, 45);
      expect(totals.totalSingleEngine, 135);
      expect(totals.totalFlightTimeMinutes, 135); // 90 + 45 = 135 (02:15)
      expect(TimeUtils.formatMinutesToHhMm(totals.totalFlightTimeMinutes), '02:15');

      expect(totals.instrumentActual, 30);
      expect(totals.instrumentFstd, 20);
      expect(totals.totalInstrument, 50);

      expect(totals.instructorSe, 90);
      expect(totals.totalInstructor, 90);

      expect(totals.landingsDay, 2);
      expect(totals.landingsNight, 1);
      expect(totals.totalLandings, 3);

      expect(totals.soloCrossCountryCount, 1);
      expect(totals.soloCrossCountryMinutes, 135);
    });

    test('Multiple flights accumulate deterministically without floating-point errors', () {
      // 1:30 (90m) + 0:45 (45m) = 2:15 (135m)
      final flight1 = createSampleFlight(
        id: 'f1',
        date: DateTime(2026, 3, 1),
        flightTimes: [
          const FlightTime(
            aircraftClass: AircraftClass.singleEngine,
            period: TimePeriod.day,
            role: PilotRole.pic,
            durationMinutes: 90,
          ),
        ],
      );

      final flight2 = createSampleFlight(
        id: 'f2',
        date: DateTime(2026, 3, 2),
        flightTimes: [
          const FlightTime(
            aircraftClass: AircraftClass.singleEngine,
            period: TimePeriod.day,
            role: PilotRole.pic,
            durationMinutes: 45,
          ),
        ],
      );

      final totals = calculator.calculateTotals([flight1, flight2]);
      expect(totals.seDayPic, 135);
      expect(totals.totalFlightTimeMinutes, 135);
      expect(TimeUtils.formatMinutesToHhMm(totals.totalFlightTimeMinutes), '02:15');
    });

    test('SE and ME splits and all role columns calculate accurately', () {
      final flight = createSampleFlight(
        id: 'f_split',
        date: DateTime(2026, 3, 5),
        fstdActualMinutes: 60, // Col 13
        flightTimes: [
          // Single Engine
          const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.dual, durationMinutes: 10),
          const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.pic, durationMinutes: 20),
          const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.picus, durationMinutes: 30),
          const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.copilot, durationMinutes: 40),
          const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.night, role: PilotRole.dual, durationMinutes: 15),
          const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.night, role: PilotRole.pic, durationMinutes: 25),
          const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.night, role: PilotRole.picus, durationMinutes: 35),
          const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.night, role: PilotRole.copilot, durationMinutes: 45),

          // Multi Engine
          const FlightTime(aircraftClass: AircraftClass.multiEngine, period: TimePeriod.day, role: PilotRole.dual, durationMinutes: 50),
          const FlightTime(aircraftClass: AircraftClass.multiEngine, period: TimePeriod.day, role: PilotRole.pic, durationMinutes: 60),
          const FlightTime(aircraftClass: AircraftClass.multiEngine, period: TimePeriod.day, role: PilotRole.picus, durationMinutes: 70),
          const FlightTime(aircraftClass: AircraftClass.multiEngine, period: TimePeriod.day, role: PilotRole.copilot, durationMinutes: 80),
          const FlightTime(aircraftClass: AircraftClass.multiEngine, period: TimePeriod.night, role: PilotRole.dual, durationMinutes: 55),
          const FlightTime(aircraftClass: AircraftClass.multiEngine, period: TimePeriod.night, role: PilotRole.pic, durationMinutes: 65),
          const FlightTime(aircraftClass: AircraftClass.multiEngine, period: TimePeriod.night, role: PilotRole.picus, durationMinutes: 75),
          const FlightTime(aircraftClass: AircraftClass.multiEngine, period: TimePeriod.night, role: PilotRole.copilot, durationMinutes: 85),
        ],
      );

      final totals = calculator.calculateFlightTotals(flight);

      expect(totals.seDayDual, 10);
      expect(totals.seDayPic, 20);
      expect(totals.seDayPicus, 30);
      expect(totals.seDayCopilot, 40);
      expect(totals.seNightDual, 15);
      expect(totals.seNightPic, 25);
      expect(totals.seNightPicus, 35);
      expect(totals.seNightCopilot, 45);

      expect(totals.meDayDual, 50);
      expect(totals.meDayPic, 60);
      expect(totals.meDayPicus, 70);
      expect(totals.meDayCopilot, 80);
      expect(totals.meNightDual, 55);
      expect(totals.meNightPic, 65);
      expect(totals.meNightPicus, 75);
      expect(totals.meNightCopilot, 85);

      expect(totals.fstdActual, 60);

      // Total SE = 10+20+30+40+15+25+35+45 = 220
      expect(totals.totalSingleEngine, 220);
      // Total ME = 50+60+70+80+55+65+75+85 = 540
      expect(totals.totalMultiEngine, 540);
      // Total flight time = 60 + 220 + 540 = 820 minutes
      expect(totals.totalFlightTimeMinutes, 820);
    });

    test('Cutoff date filters out flights strictly after cutoff date (inclusive)', () {
      final flights = [
        createSampleFlight(
          id: 'f1',
          date: DateTime(2026, 1, 15),
          flightTimes: [const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.pic, durationMinutes: 60)],
        ),
        createSampleFlight(
          id: 'f2',
          date: DateTime(2026, 2, 1),
          flightTimes: [const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.pic, durationMinutes: 60)],
        ),
        createSampleFlight(
          id: 'f3',
          date: DateTime(2026, 2, 15),
          flightTimes: [const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.pic, durationMinutes: 60)],
        ),
      ];

      final cutoff = DateTime(2026, 2, 1);
      final totals = calculator.calculateTotals(flights, cutoffDate: cutoff);

      expect(totals.totalFlightTimeMinutes, 120); // Only f1 and f2 included
    });

    test('Pagination produces correct pages, page totals, and carry forward invariants', () {
      // Create 30 flights of 60 mins each
      final flights = List.generate(
        30,
        (i) => createSampleFlight(
          id: 'f_$i',
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          flightTimes: [
            const FlightTime(
              aircraftClass: AircraftClass.singleEngine,
              period: TimePeriod.day,
              role: PilotRole.pic,
              durationMinutes: 60,
            ),
          ],
          landings: const Landings(dayCount: 1),
        ),
      );

      // Default 14 entries per page:
      // Page 1: 14 flights -> 14h (840m)
      // Page 2: 14 flights -> 14h (840m), BF: 14h, CF: 28h (1680m)
      // Page 3: 2 flights -> 2h (120m), BF: 28h, CF: 30h (1800m)
      final pages = calculator.paginateLedger(flights, entriesPerPage: 14);

      expect(pages.length, 3);

      // Page 1
      expect(pages[0].pageNumber, 1);
      expect(pages[0].entries.length, 14);
      expect(pages[0].broughtForward.totalFlightTimeMinutes, 0);
      expect(pages[0].pageTotals.totalFlightTimeMinutes, 840);
      expect(pages[0].carriedForward.totalFlightTimeMinutes, 840);
      expect(pages[0].isValidCarryForward, isTrue);

      // Page 2
      expect(pages[1].pageNumber, 2);
      expect(pages[1].entries.length, 14);
      expect(pages[1].broughtForward.totalFlightTimeMinutes, 840);
      expect(pages[1].pageTotals.totalFlightTimeMinutes, 840);
      expect(pages[1].carriedForward.totalFlightTimeMinutes, 1680);
      expect(pages[1].isValidCarryForward, isTrue);

      // Page 3
      expect(pages[2].pageNumber, 3);
      expect(pages[2].entries.length, 2);
      expect(pages[2].broughtForward.totalFlightTimeMinutes, 1680);
      expect(pages[2].pageTotals.totalFlightTimeMinutes, 120);
      expect(pages[2].carriedForward.totalFlightTimeMinutes, 1800);
      expect(pages[2].isValidCarryForward, isTrue);
      expect(pages[2].carriedForward.totalLandings, 30);
    });

    test('Pagination with initial brought forward value carries forward accurately', () {
      final initialBF = const LedgerTotals(
        seDayPic: 600, // 10h
        landingsDay: 20,
      );

      final flights = [
        createSampleFlight(
          id: 'f1',
          date: DateTime(2026, 1, 1),
          flightTimes: [
            const FlightTime(
              aircraftClass: AircraftClass.singleEngine,
              period: TimePeriod.day,
              role: PilotRole.pic,
              durationMinutes: 120, // 2h
            ),
          ],
          landings: const Landings(dayCount: 2),
        ),
      ];

      final pages = calculator.paginateLedger(
        flights,
        entriesPerPage: 14,
        initialBroughtForward: initialBF,
      );

      expect(pages.length, 1);
      expect(pages[0].broughtForward.seDayPic, 600);
      expect(pages[0].pageTotals.seDayPic, 120);
      expect(pages[0].carriedForward.seDayPic, 720);
      expect(pages[0].carriedForward.landingsDay, 22);
      expect(pages[0].isValidCarryForward, isTrue);
    });

    test('Rolling 12-month summary covers exact 12-month period', () {
      final asOf = DateTime(2026, 6, 1);
      final flights = [
        // Inside 12 months
        createSampleFlight(
          id: 'f_inside_1',
          date: DateTime(2025, 6, 2),
          flightTimes: [const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.pic, durationMinutes: 60)],
        ),
        createSampleFlight(
          id: 'f_inside_2',
          date: DateTime(2026, 6, 1),
          flightTimes: [const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.pic, durationMinutes: 60)],
        ),
        // Outside (too old)
        createSampleFlight(
          id: 'f_old',
          date: DateTime(2025, 5, 30),
          flightTimes: [const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.pic, durationMinutes: 60)],
        ),
        // Outside (future)
        createSampleFlight(
          id: 'f_future',
          date: DateTime(2026, 6, 2),
          flightTimes: [const FlightTime(aircraftClass: AircraftClass.singleEngine, period: TimePeriod.day, role: PilotRole.pic, durationMinutes: 60)],
        ),
      ];

      final rollingTotals = calculator.calculateRolling12Months(flights, asOfDate: asOf);
      expect(rollingTotals.totalFlightTimeMinutes, 120); // Only f_inside_1 and f_inside_2
    });
  });
}

