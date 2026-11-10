import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart' as sql;

import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/backups/data/backup_archive_service.dart';
import 'package:aviation_logbook/features/backups/data/backup_service.dart';
import 'package:aviation_logbook/features/backups/domain/backup_encryptor.dart';
import 'package:aviation_logbook/features/flights/data/flight_drafts_repository.dart';
import 'package:aviation_logbook/features/flights/data/flights_repository.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/domain/flight_draft.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 10);
  Flight flight() => Flight(
    id: 'f1',
    date: now,
    registration: 'ZS-ABC',
    picName: 'SELF',
    createdAt: now,
    updatedAt: now,
  );
  FlightDraft draft({String? flightId, String? revision}) => FlightDraft(
    flightId: flightId,
    baseRevision: revision,
    updatedAt: now,
    fields: {'decimal': '1.', 'remarks': '未完成 ✈', 'hobbsEnd': ''},
    validatedValues: {'durationMinutes': 90, 'hobbsStartTenths': 54867},
  );

  test(
    'raw incomplete input and integer values round trip without a Flight',
    () {
      final original = draft();
      final restored = FlightDraft.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored.fields, original.fields);
      expect(restored.validatedValues, original.validatedValues);
      expect(() => restored.fields['decimal'] = '2', throwsUnsupportedError);
    },
  );

  test(
    'draft survives database close/reopen and v6 migration preserves flights',
    () async {
      final dir = await Directory.systemTemp.createTemp('draft_recovery_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/logbook.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await FlightsRepository(db.flightsDao).saveFlight(flight());
      await db.customStatement('DROP TABLE flight_drafts');
      await db.customStatement('PRAGMA user_version = 6');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      await SqliteFlightDraftRepository(db).save(draft());
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      expect(
        (await SqliteFlightDraftRepository(db).get(null))?.fields,
        containsPair('decimal', '1.'),
      );
      expect(
        await FlightsRepository(db.flightsDao).getAllFlights(),
        hasLength(1),
      );
    },
  );

  test('encrypted portable backup restores drafts as drafts; old backup clears them', () async {
    final source = AppDatabase(NativeDatabase.memory());
    final target = AppDatabase(NativeDatabase.memory());
    final old = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);
    addTearDown(old.close);
    await SqliteFlightDraftRepository(source).save(draft());
    final service = BackupService(db: source);
    final archive = BackupArchiveService();
    final zip = await archive.createZipArchive(
      databaseBytes: await service.createPortableDatabaseSnapshot(),
      documentFiles: [],
      flightCount: 0,
      aircraftModelCount: 0,
      schemaVersion: source.schemaVersion,
    );
    final encryptor = BackupEncryptor(
      kdf: Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 1000, bits: 256),
    );
    final encrypted = await encryptor.encrypt(
      clearBytes: zip,
      passphrase: 'test',
    );
    final clear = await encryptor.decrypt(
      encryptedBytes: encrypted,
      passphrase: 'test',
    );
    final extracted = await archive.unpackAndValidateZip(clear);
    await BackupService(db: target).restorePortableSnapshot(extracted);
    expect(
      (await SqliteFlightDraftRepository(target).get(null))?.fields,
      draft().fields,
    );
    expect(await FlightsRepository(target.flightsDao).getAllFlights(), isEmpty);
    // Export a fixture without the new table, as real older backups have none.
    final oldBytes = await BackupService(db: old)
        .createPortableDatabaseSnapshot();
    final dir = await Directory.systemTemp.createTemp('old_draft_backup_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/old.sqlite')..writeAsBytesSync(oldBytes);
    final sqlite = sql.sqlite3.open(file.path);
    sqlite.execute('DROP TABLE flight_drafts');
    sqlite.execute('PRAGMA user_version = 6');
    sqlite.close();
    final oldZip = await archive.createZipArchive(
      databaseBytes: await file.readAsBytes(),
      documentFiles: [],
      flightCount: 0,
      aircraftModelCount: 0,
      schemaVersion: 6,
    );
    // The absent-table path is covered separately below.
    await BackupService(db: target)
        .restorePortableSnapshot(await archive.unpackAndValidateZip(oldZip));
    expect(await SqliteFlightDraftRepository(target).get(null), isNull);
  });

  test(
    'finalize is atomic, rejects newer or deleted originals and keeps drafts',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final flights = FlightsRepository(db.flightsDao);
      final drafts = SqliteFlightDraftRepository(db);
      await flights.saveFlight(flight());
      final revision = await drafts.revision('f1');
      await drafts.save(draft(flightId: 'f1', revision: revision));
      // Change content without advancing the second-resolution timestamp.
      await db.customStatement(
        "UPDATE flights_table SET remarks = 'newer' WHERE id = 'f1'",
      );
      await expectLater(
        drafts.finalize(flight(), baseRevision: revision),
        throwsA(isA<FlightDraftConflict>()),
      );
      expect(await drafts.get('f1'), isNotNull);
      expect((await flights.getAllFlights()).single.remarks, 'newer');
      await flights.deleteFlight('f1');
      await expectLater(
        drafts.finalize(flight(), baseRevision: revision),
        throwsA(isA<FlightDraftConflict>()),
      );
      expect(await drafts.get('f1'), isNotNull);
      await drafts.save(draft());
      await db.customStatement(
        "CREATE TRIGGER fail_save BEFORE INSERT ON flights_table BEGIN SELECT RAISE(ABORT, 'disk failure'); END",
      );
      await expectLater(
        drafts.finalize(flight(), baseRevision: null),
        throwsA(anything),
      );
      expect(await drafts.get(null), isNotNull);
      expect(await flights.getAllFlights(), isEmpty);
      await db.customStatement('DROP TRIGGER fail_save');
      await drafts.finalize(flight(), baseRevision: null);
      expect(await drafts.get(null), isNull);
      expect(await flights.getAllFlights(), hasLength(1));
    },
  );
}
