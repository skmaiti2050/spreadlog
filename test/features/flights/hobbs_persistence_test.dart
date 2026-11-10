import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';

import 'dart:io';

import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/backups/data/backup_archive_service.dart';
import 'package:aviation_logbook/features/backups/data/backup_service.dart';
import 'package:aviation_logbook/features/flights/data/flights_repository.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Hobbs readings and adjusted duration survive portable backup restore',
    () async {
      final source = AppDatabase(NativeDatabase.memory());
      final target = AppDatabase(NativeDatabase.memory());
      addTearDown(source.close);
      addTearDown(target.close);
      final now = DateTime(2026);
      await FlightsRepository(source.flightsDao).saveFlight(
        Flight(
          id: 'hobbs',
          date: now,
          aircraftModelId: 'ONEOFF',
          aircraftCategory: AircraftCategory.helicopter,
          registration: 'ZS-ABC',
          picName: 'SELF',
          hobbsStartTenths: 54867,
          hobbsEndTenths: 54882,
          durationSource: 'hobbs',
          durationAdjustmentReason: 'School adjustment',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final data = await BackupService(db: source)
          .createPortableDatabaseSnapshot();
      final archive = BackupArchiveService();
      final bytes = await archive.createZipArchive(
        databaseBytes: data,
        documentFiles: [],
        flightCount: 1,
        aircraftModelCount: 1,
        schemaVersion: source.schemaVersion,
        pilotProfile: {'pilotName': 'Pilot', 'licenceNumber': '123'},
      );
      final unpacked = await archive.unpackAndValidateZip(bytes);
      expect(unpacked.manifest.pilotProfile?['pilotName'], 'Pilot');
      await BackupService(db: target).restorePortableSnapshot(unpacked);
      final restored = (await FlightsRepository(
        target.flightsDao,
      ).getAllFlights()).single;
      expect(restored.hobbsStartTenths, 54867);
      expect(restored.hobbsEndTenths, 54882);
      expect(restored.durationSource, 'hobbs');
      expect(restored.durationAdjustmentReason, 'School adjustment');
      final model = await target.aircraftDao.getModelById('ONEOFF');
      expect(model?.manufacturer, isEmpty);
      expect(model?.category, AircraftCategory.helicopter.index);
      expect(restored.aircraftCategory, AircraftCategory.helicopter);
    },
  );

  test(
    'version 5 upgrades existing flights without inventing meter readings',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'hobbs_migration_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/logbook.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());
      final now = DateTime(2026);
      await FlightsRepository(db.flightsDao).saveFlight(
        Flight(
          id: 'old',
          date: now,
          registration: 'ZS-OLD',
          picName: 'SELF',
          createdAt: now,
          updatedAt: now,
        ),
      );
      for (final column in [
        'hobbs_start_tenths',
        'hobbs_end_tenths',
        'duration_source',
        'duration_adjustment_reason',
      ]) {
        await db.customStatement(
          'ALTER TABLE flights_table DROP COLUMN $column',
        );
      }
      await db.customStatement('DROP TABLE flight_drafts');
      await db.customStatement('PRAGMA user_version = 5');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final old = (await FlightsRepository(
        db.flightsDao,
      ).getAllFlights()).single;
      expect(old.id, 'old');
      expect(old.hobbsStartTenths, isNull);
      expect(old.hobbsEndTenths, isNull);
      expect(old.durationSource, 'hhMm');
    },
  );
}
