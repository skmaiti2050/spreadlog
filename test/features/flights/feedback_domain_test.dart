import 'package:aviation_logbook/core/utils/time_utils.dart';
import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/domain/flight_time.dart';
import 'package:aviation_logbook/features/flights/domain/hobbs_reading.dart';
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

}
