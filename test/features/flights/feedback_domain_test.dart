import 'package:aviation_logbook/core/utils/time_utils.dart';
import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/domain/flight_filter.dart';
import 'package:aviation_logbook/features/flights/domain/flight_time.dart';
import 'package:aviation_logbook/features/flights/domain/hobbs_reading.dart';
import 'package:aviation_logbook/features/flights/domain/ledger_calculator.dart';
import 'package:aviation_logbook/features/regulators/domain/sacaa_profile.dart';
import 'package:flutter_test/flutter_test.dart';

Flight flight(
  String id,
  DateTime date, {
  String registration = 'ZS-ABC',
  String model = 'C172',
  int duration = 90,
  int? hobbsEnd,
}) => Flight(
  id: id,
  date: date,
  aircraftModelId: model,
  registration: registration,
  picName: 'SELF',
  hobbsEndTenths: hobbsEnd,
  createdAt: date,
  updatedAt: date,
  flightTimes: [
    FlightTime(
      aircraftClass: AircraftClass.singleEngine,
      period: TimePeriod.day,
      role: PilotRole.pic,
      durationMinutes: duration,
    ),
  ],
);

void main() {
  test('decimal tenths and Hobbs subtraction are exact integers', () {
    expect(TimeUtils.tryParseDecimalToMinutes('1.5'), 90);
    expect(TimeUtils.tryParseDecimalToMinutes('0.1'), 6);
    expect(TimeUtils.tryParseDecimalToMinutes('2'), 120);
    final start = TimeUtils.tryParseHourTenths('5486.7')!;
    final end = TimeUtils.tryParseHourTenths('5488.2')!;
    expect(HobbsReading(startTenths: start, endTenths: end).elapsedMinutes, 90);
    for (final input in [
      'NaN',
      'Infinity',
      '-1',
      '1.25',
      '1e2',
      '1.',
      '.5',
      '',
    ]) {
      expect(TimeUtils.tryParseDecimalToMinutes(input), isNull, reason: input);
    }
    expect(
      () => HobbsReading(startTenths: 10, endTenths: 9),
      throwsArgumentError,
    );
    expect(
      () => HobbsReading(startTenths: 10, endTenths: 10),
      throwsArgumentError,
    );
    for (var tenth = 0; tenth < 10000; tenth++) {
      expect(
        TimeUtils.tryParseHourTenths(TimeUtils.formatHourTenths(tenth)),
        tenth,
      );
    }
  });

  test(
    'prefill uses same registration, excludes future dates and edited flight',
    () {
      final flights = [
        flight('old', DateTime(2026, 1), hobbsEnd: 100),
        flight(
          'other',
          DateTime(2026, 2),
          registration: 'ZS-XYZ',
          hobbsEnd: 500,
        ),
        flight('recent', DateTime(2026, 3), hobbsEnd: 120),
        flight('editing', DateTime(2026, 4), hobbsEnd: 130),
        flight('future', DateTime(2026, 5), hobbsEnd: 140),
      ];
      expect(
        HobbsReading.previousEnd(
          flights,
          registration: 'zs abc',
          date: DateTime(2026, 4),
          excludingId: 'editing',
        ),
        120,
      );
      expect(
        HobbsReading.previousEnd(
          flights,
          registration: 'ZS-NEW',
          date: DateTime(2026, 4),
        ),
        isNull,
      );
    },
  );

  test(
    'combined filters include the whole final day and search model names',
    () {
      final flights = [
        flight('before', DateTime(2025, 12, 31)),
        flight('first', DateTime(2026, 1, 1)),
        flight('last', DateTime(2026, 1, 31, 23, 59)),
        flight(
          'other',
          DateTime(2026, 1, 12),
          registration: 'ZS-XYZ',
          model: 'PA28',
        ),
        flight('after', DateTime(2026, 2, 1)),
      ];
      final filter = FlightFilter(
        query: 'cessna',
        startDate: DateTime(2026, 1),
        endDate: DateTime(2026, 1, 31),
        registrations: {'ZS-ABC'},
        modelIds: {'C172'},
        category: AircraftCategory.aeroplane,
        aircraftClass: AircraftClass.singleEngine,
        role: PilotRole.pic,
        period: TimePeriod.day,
      );
      final selected = filter.apply(
        flights,
        models: {
          'C172': const AircraftModel(
            id: 'C172',
            manufacturer: 'Cessna',
            model: '172',
            aircraftClass: AircraftClass.singleEngine,
            category: AircraftCategory.aeroplane,
          ),
        },
      );
      expect(selected.map((f) => f.id), ['last', 'first']);
      expect(
        const LedgerCalculator()
            .calculateTotals(selected)
            .totalFlightTimeMinutes,
        180,
      );
      expect(flights.first.id, 'before');
      expect(const FlightFilter(role: PilotRole.dual).apply(flights), isEmpty);
    },
  );

  test(
    'multi-selection unions values and sorting is stable and reversible',
    () {
      final flights = [
        flight('b', DateTime(2026), duration: 60),
        flight('a', DateTime(2026), duration: 60),
        flight('c', DateTime(2026), registration: 'ZS-XYZ', duration: 120),
      ];
      final selected = const FlightFilter(
        registrations: {'ZS-ABC', 'ZS-XYZ'},
        sort: FlightSort.duration,
      ).apply(flights);
      expect(selected.map((f) => f.id), ['a', 'b', 'c']);
      expect(
        const FlightFilter(
          sort: FlightSort.duration,
          descending: true,
        ).apply(flights).map((f) => f.id),
        ['c', 'b', 'a'],
      );
    },
  );

  test('regulator forwards start and cutoff dates', () {
    final flights = [
      flight('old', DateTime(2025)),
      flight('in', DateTime(2026, 2, 28)),
      flight('out', DateTime(2026, 3)),
    ];
    final totals = const SacaaProfile().calculateTotals(
      flights,
      startDate: DateTime(2026, 2),
      cutoffDate: DateTime(2026, 2, 28),
    );
    expect(totals.totalFlightTimeMinutes, 90);
  });
}
