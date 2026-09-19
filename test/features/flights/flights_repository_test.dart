import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/flights/data/flights_repository.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/domain/flight_time.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FlightsRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = FlightsRepository(db.flightsDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('FlightsRepository Integration Tests', () {
    test('saveFlight automatically satisfies foreign key for dynamic aircraftModelId', () async {
      final now = DateTime(2026, 9, 19, 10, 0);
      final flight = Flight(
        id: 'test_flt_1',
        date: now,
        aircraftModelId: 'C172',
        registration: 'ZS-EXT',
        picName: 'SELF',
        remarks: 'Local Circuit Training',
        flightTimes: const [
          FlightTime(
            aircraftClass: AircraftClass.singleEngine,
            period: TimePeriod.day,
            role: PilotRole.pic,
            durationMinutes: 90,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      // This previously failed with SqliteException: FOREIGN KEY constraint failed
      await repository.saveFlight(flight);

      final retrieved = await repository.getAllFlights();
      expect(retrieved.length, 1);
      expect(retrieved.first.id, 'test_flt_1');
      expect(retrieved.first.aircraftModelId, 'C172');
      expect(retrieved.first.registration, 'ZS-EXT');
    });

    test('deleteFlights deletes multiple flights in a single batch', () async {
      final now = DateTime(2026, 9, 19, 10, 0);

      final flight1 = Flight(
        id: 'flt_1',
        date: now,
        aircraftModelId: 'C172',
        registration: 'ZS-AAA',
        picName: 'SELF',
        createdAt: now,
        updatedAt: now,
      );

      final flight2 = Flight(
        id: 'flt_2',
        date: now,
        aircraftModelId: 'BE76',
        registration: 'ZS-BBB',
        picName: 'SELF',
        createdAt: now,
        updatedAt: now,
      );

      final flight3 = Flight(
        id: 'flt_3',
        date: now,
        aircraftModelId: 'PA28',
        registration: 'ZS-CCC',
        picName: 'SELF',
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveFlight(flight1);
      await repository.saveFlight(flight2);
      await repository.saveFlight(flight3);

      var all = await repository.getAllFlights();
      expect(all.length, 3);

      final deletedCount = await repository.deleteFlights(['flt_1', 'flt_3']);
      expect(deletedCount, 2);

      all = await repository.getAllFlights();
      expect(all.length, 1);
      expect(all.first.id, 'flt_2');
    });
  });
}

