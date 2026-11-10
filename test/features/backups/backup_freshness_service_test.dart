import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/backups/data/backup_freshness_service.dart';
import 'package:aviation_logbook/features/flights/data/flights_repository.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/profile/data/pilot_profile_repository.dart';
import 'package:aviation_logbook/features/profile/domain/pilot_profile.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late BackupFreshnessService service;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    service = BackupFreshnessService(db, preferences: MemoryPreferences());
  });
  tearDown(() => db.close());

  test(
    'freshness detects inserts, deletions, profile and Fleet changes',
    () async {
      final empty = await service.fingerprint();
      expect(
        (await service.status(empty, 'pilot@example.com')).pending,
        isTrue,
      );
      await service.recordSuccess(empty, 'pilot@example.com');
      expect(
        (await service.status(empty, 'PILOT@example.com')).pending,
        isFalse,
      );
      expect(
        (await service.status(empty, 'other@example.com')).lastSuccess,
        isNull,
      );
      final repo = FlightsRepository(db.flightsDao);
      final now = DateTime(2026);
      await repo.saveFlight(
        Flight(
          id: 'one',
          date: now,
          registration: 'ZS-ABC',
          aircraftModelId: 'NEW',
          picName: 'SELF',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final inserted = await service.fingerprint();
      expect(inserted, isNot(empty));
      await service.recordSuccess(inserted, 'pilot@example.com');
      await repo.deleteFlight('one');
      expect(
        (await service.status(
          await service.fingerprint(),
          'pilot@example.com',
        )).pending,
        isTrue,
      );
      final deleted = await service.fingerprint();
      await service.recordSuccess(deleted, 'pilot@example.com');
      await const PilotProfileRepository().saveProfile(
        const PilotProfile(pilotName: 'New name'),
      );
      expect(
        (await service.status(
          await service.fingerprint(),
          'pilot@example.com',
        )).pending,
        isTrue,
      );
      final profile = await service.fingerprint();
      await db.customStatement(
        "UPDATE aircraft_models_table SET manufacturer = 'Maker' WHERE id = 'NEW'",
      );
      expect(await service.fingerprint(), isNot(profile));
    },
  );

  test('upload completion only acknowledges captured content', () async {
    final snapshot = await service.fingerprint();
    await db.flightsDao.ensureAircraftModelExists(modelId: 'LATE');
    await service.recordSuccess(snapshot, 'pilot@example.com');
    final status = await service.status(
      await service.fingerprint(),
      'pilot@example.com',
    );
    expect(status.pending, isTrue);
    expect(status.lastSuccess, isNotNull);
  });
}
