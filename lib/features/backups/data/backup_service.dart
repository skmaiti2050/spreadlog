import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:typed_data/typed_buffers.dart';

import '../../../../core/database/app_database.dart';
import '../domain/backup_encryptor.dart';
import '../domain/backup_exceptions.dart';
import '../domain/backup_manifest.dart';
import 'backup_archive_service.dart';
import 'sqlite_loader/sqlite_loader.dart';

/// Inspection result produced before committing a restore.
class BackupInspectionResult {
  final BackupManifest manifest;
  final int totalSizeBytes;
  final bool isIntegrityVerified;
  final ExtractedBackup? extractedBackup;

  const BackupInspectionResult({
    required this.manifest,
    required this.totalSizeBytes,
    required this.isIntegrityVerified,
    this.extractedBackup,
  });
}

/// Main orchestration service for creating encrypted backups, inspecting archive integrity,
/// and safely restoring database and document files across mobile, desktop, and web.
class BackupService {
  final AppDatabase db;
  final BackupEncryptor _encryptor;
  final BackupArchiveService _archiveService;
  final Future<String> Function() _appVersion;

  BackupService({
    required this.db,
    BackupEncryptor? encryptor,
    BackupArchiveService? archiveService,
    Future<String> Function()? appVersion,
  }) : _encryptor = encryptor ?? BackupEncryptor(),
       _archiveService = archiveService ?? BackupArchiveService(),
       _appVersion = appVersion ?? _platformAppVersion;

  static Future<String> _platformAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Rejects archives written by a newer app build. Drift cannot downgrade a
  /// schema, so opening such a database would fail or corrupt data.
  void _ensureCompatible(BackupManifest manifest) {
    if (manifest.schemaVersion > db.schemaVersion) {
      throw BackupException(
        'This backup was created by a newer version of Spreadlog '
        '(data version ${manifest.schemaVersion}, this app supports '
        '${db.schemaVersion}). Update the app before restoring it.',
      );
    }
  }

  /// Creates a full, tamper-evident, encrypted `.spbackup` binary archive.
  Future<Uint8List> createEncryptedBackup({required String passphrase}) async {
    // 1. Gather stats from database
    final flights = await db.flightsDao.getAllFlights();
    final models = await db.aircraftDao.getAllModels();

    // 2. Read SQLite database bytes & documents
    final Uint8List dbBytes;
    final List<ArchiveFileItem> documentFiles;

    if (kIsWeb) {
      dbBytes = await _createWebDatabaseSnapshot();
      documentFiles = await _collectWebDocumentFiles();
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbFile = File(
        p.join(docsDir.path, 'database', 'app_database.sqlite'),
      );

      // Checkpoint WAL first to flush all pending writes into the main file
      try {
        await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
      } catch (_) {}

      if (await dbFile.exists()) {
        dbBytes = await dbFile.readAsBytes();
      } else {
        throw const BackupException('Database file not found on disk.');
      }

      documentFiles = await _collectNativeDocumentFiles(docsDir);
    }

    // 3. Create ZIP archive with manifest.json and checksums
    final zipBytes = await _archiveService.createZipArchive(
      databaseBytes: dbBytes,
      documentFiles: documentFiles,
      flightCount: flights.length,
      aircraftModelCount: models.length,
      schemaVersion: db.schemaVersion,
      appVersion: await _appVersion(),
      createdAt: DateTime.now().toUtc(),
    );

    // 4. Encrypt ZIP with AES-256-GCM + PBKDF2
    final encryptedBytes = await _encryptor.encrypt(
      clearBytes: zipBytes,
      passphrase: passphrase,
    );

    return encryptedBytes;
  }

  /// Inspects and validates an encrypted `.spbackup` archive without applying it.
  /// Returns the inspection result along with the pre-extracted archive to avoid
  /// redundant 100k iteration PBKDF2 re-decryption on restoration.
  Future<BackupInspectionResult> inspectBackup({
    required Uint8List backupBytes,
    required String passphrase,
  }) async {
    // 1. Decrypt
    final zipBytes = await _encryptor.decrypt(
      encryptedBytes: backupBytes,
      passphrase: passphrase,
    );

    // 2. Unpack & Validate Checksums
    final extracted = await _archiveService.unpackAndValidateZip(zipBytes);
    _ensureCompatible(extracted.manifest);

    return BackupInspectionResult(
      manifest: extracted.manifest,
      totalSizeBytes: backupBytes.length,
      isIntegrityVerified: true,
      extractedBackup: extracted,
    );
  }

  /// Restores database and endorsement files from an encrypted `.spbackup` archive.
  ///
  /// Employs rollback protection: if an I/O failure occurs while writing new files,
  /// the active database is restored to its pre-restore state.
  Future<BackupManifest> restoreBackup({
    required Uint8List backupBytes,
    required String passphrase,
    ExtractedBackup? preExtractedBackup,
  }) async {
    // 1. Decrypt & Unpack (or reuse pre-extracted archive)
    final ExtractedBackup extracted;
    if (preExtractedBackup != null) {
      extracted = preExtractedBackup;
    } else {
      final zipBytes = await _encryptor.decrypt(
        encryptedBytes: backupBytes,
        passphrase: passphrase,
      );
      extracted = await _archiveService.unpackAndValidateZip(zipBytes);
    }
    _ensureCompatible(extracted.manifest);

    // 2. Web Restoration
    if (kIsWeb) {
      await _restoreWeb(extracted);
      return extracted.manifest;
    }

    // 3. Native File Restoration with Rollback Safety
    final docsDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(docsDir.path, 'database'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbFile = File(p.join(dbDir.path, 'app_database.sqlite'));
    final rollbackFile = File(
      p.join(dbDir.path, 'app_database.sqlite.rollback'),
    );
    final walFile = File(p.join(dbDir.path, 'app_database.sqlite-wal'));
    final shmFile = File(p.join(dbDir.path, 'app_database.sqlite-shm'));
    final journalFile = File(p.join(dbDir.path, 'app_database.sqlite-journal'));

    // Step 3a: Checkpoint and close existing connection with timeout
    try {
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (_) {}

    try {
      await db.close().timeout(const Duration(seconds: 2));
    } catch (_) {}

    // Step 3b: Create rollback safety copy of active database
    if (await dbFile.exists()) {
      await dbFile.copy(rollbackFile.path);
    }

    // Page images created by this restore; removed again if it fails.
    final writtenFiles = <File>[];
    final endorsementsDir = Directory(p.join(docsDir.path, 'endorsements'));

    try {
      // Step 3c: Delete stale WAL and journal files to prevent corruption on reconnect
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();
      if (await journalFile.exists()) await journalFile.delete();

      // Step 3d: Overwrite database file
      await dbFile.writeAsBytes(extracted.databaseBytes, flush: true);

      // Step 3e: Overwrite / restore endorsement files
      if (!await endorsementsDir.exists()) {
        await endorsementsDir.create(recursive: true);
      }

      for (final doc in extracted.documentFiles) {
        final fileName = p.basename(doc.path);
        final targetFile = File(p.join(endorsementsDir.path, fileName));
        if (!await targetFile.exists()) writtenFiles.add(targetFile);
        await targetFile.writeAsBytes(doc.bytes, flush: true);
      }

      final sqlite = await getPlatformSqliteLoader().load();
      final restoredDb = sqlite.open(dbFile.path);
      try {
        final columns = restoredDb
            .select('PRAGMA table_info(endorsement_documents_table)')
            .map((r) => r['name'])
            .toSet();
        final hasPages = columns.contains('pages_json');
        final files = {
          for (final f in extracted.documentFiles) p.basename(f.path): f,
        };
        String relocate(String path, int index) {
          if (path.startsWith('data:')) return path;
          final name = p.windows.basename(path);
          if (!files.containsKey(name)) {
            throw const BackupException('Missing document page in backup');
          }
          return p.join(endorsementsDir.path, name);
        }

        restoredDb.execute('BEGIN');
        for (final row
            in columns.isEmpty
                ? <Row>[]
                : restoredDb.select(
                    'SELECT * FROM endorsement_documents_table',
                  )) {
          final path = relocate(row['original_path'] as String, 0);
          if (hasPages) {
            final manifest = _mapPagePaths(
              row['pages_json'] as String?,
              relocate,
            );
            restoredDb.execute(
              'UPDATE endorsement_documents_table SET original_path = ?, pages_json = ? WHERE id = ?',
              [path, manifest, row['id']],
            );
          } else {
            restoredDb.execute(
              'UPDATE endorsement_documents_table SET original_path = ? WHERE id = ?',
              [path, row['id']],
            );
          }
        }
        restoredDb.execute('COMMIT');
      } finally {
        restoredDb.close();
      }

      // Restore succeeded, clean up rollback safety copy
      if (await rollbackFile.exists()) {
        await rollbackFile.delete();
      }

      // The restored database references only the archive's pages; images
      // left from the replaced logbook would otherwise accumulate forever.
      final kept = {
        for (final doc in extracted.documentFiles) p.basename(doc.path),
      };
      await for (final entity in endorsementsDir.list()) {
        if (entity is File && !kept.contains(p.basename(entity.path))) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }

      return extracted.manifest;
    } catch (e) {
      // Rollback on failure
      if (await rollbackFile.exists()) {
        await rollbackFile.copy(dbFile.path);
        await rollbackFile.delete();
      }
      for (final file in writtenFiles) {
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      throw BackupException('Failed to restore backup: $e', e);
    }
  }

  // --- WEB RESTORATION ENGINE ---
  Future<void> _restoreWeb(ExtractedBackup extracted) async {
    final sqlite = await getPlatformSqliteLoader().load();
    final fs = InMemoryFileSystem(
      name: 'mem_restore_${DateTime.now().microsecondsSinceEpoch}',
    );
    fs.fileData['/backup.sqlite'] = Uint8Buffer()
      ..addAll(extracted.databaseBytes);
    sqlite.registerVirtualFileSystem(fs, makeDefault: false);
    final sourceDb = sqlite.open('/backup.sqlite', vfs: fs.name);

    try {
      final tableRows = sourceDb.select(
        "SELECT name FROM sqlite_master WHERE type='table';",
      );
      final availableTables = tableRows.map((r) => r['name'] as String).toSet();

      final modelsRows = _readTable(
        sourceDb,
        availableTables,
        'aircraft_models_table',
        'aircraft_models',
      );
      final flightsRows = _readTable(
        sourceDb,
        availableTables,
        'flights_table',
        'flights',
      );
      final flightTimesRows = _readTable(
        sourceDb,
        availableTables,
        'flight_times_table',
        'flight_times',
      );
      final instructionTimesRows = _readTable(
        sourceDb,
        availableTables,
        'instruction_times_table',
        'instruction_times',
      );
      final instrumentTimesRows = _readTable(
        sourceDb,
        availableTables,
        'instrument_times_table',
        'instrument_times',
      );
      final landingsRows = _readTable(
        sourceDb,
        availableTables,
        'landings_table',
        'landings',
      );
      final docsRows = _readTable(
        sourceDb,
        availableTables,
        'endorsement_documents_table',
        'endorsement_documents',
      );
      final correctionRows = _readTable(
        sourceDb,
        availableTables,
        'endorsement_corrections',
        'endorsement_corrections',
      );
      final modelEndorsementsRows = _readTable(
        sourceDb,
        availableTables,
        'model_endorsements_table',
        'model_endorsements',
      );

      final docFileMap = <String, Uint8List>{};
      for (final doc in extracted.documentFiles) {
        docFileMap[p.basename(doc.path)] = doc.bytes;
        docFileMap[doc.path] = doc.bytes;
      }

      await db.transaction(() async {
        await db.customStatement('PRAGMA foreign_keys = OFF;');

        await db.customStatement('DELETE FROM endorsement_corrections');
        for (final row in correctionRows) {
          await db.customStatement(
            'INSERT INTO endorsement_corrections (endorsement_id, aircraft_model_id, removed_at, reason, snapshot) VALUES (?, ?, ?, ?, ?)',
            [
              row['endorsement_id'],
              row['aircraft_model_id'],
              row['removed_at'],
              row['reason'],
              row['snapshot'],
            ],
          );
        }
        await db.delete(db.modelEndorsementsTable).go();
        await db.delete(db.endorsementDocumentsTable).go();
        await db.delete(db.flightTimesTable).go();
        await db.delete(db.instructionTimesTable).go();
        await db.delete(db.instrumentTimesTable).go();
        await db.delete(db.landingsTable).go();
        await db.delete(db.flightsTable).go();
        await db.delete(db.aircraftModelsTable).go();

        for (final row in modelsRows) {
          await db
              .into(db.aircraftModelsTable)
              .insert(
                AircraftModelsTableCompanion(
                  id: Value(row['id'] as String),
                  manufacturer: Value(row['manufacturer'] as String),
                  model: Value(row['model'] as String),
                  aircraftClass: Value(row['aircraft_class'] as int),
                  category: Value(row['category'] as int),
                  createdAt: Value(_parseDateTime(row['created_at'])),
                ),
              );
        }

        for (final row in flightsRows) {
          await db
              .into(db.flightsTable)
              .insert(
                FlightsTableCompanion(
                  id: Value(row['id'] as String),
                  date: Value(_parseDateTime(row['date'])),
                  aircraftModelId: Value(row['aircraft_model_id'] as String?),
                  registration: Value(row['registration'] as String),
                  picName: Value(row['pic_name'] as String),
                  remarks: Value((row['remarks'] as String?) ?? ''),
                  soloCrossCountry: Value(
                    _parseBool(row['solo_cross_country']),
                  ),
                  fstdActualMinutes: Value(
                    (row['fstd_actual_minutes'] as int?) ?? 0,
                  ),
                  createdAt: Value(_parseDateTime(row['created_at'])),
                  updatedAt: Value(_parseDateTime(row['updated_at'])),
                ),
              );
        }

        for (final row in flightTimesRows) {
          await db
              .into(db.flightTimesTable)
              .insert(
                FlightTimesTableCompanion(
                  id: Value(row['id'] as String),
                  flightId: Value(row['flight_id'] as String),
                  aircraftClass: Value(row['aircraft_class'] as int),
                  period: Value(row['period'] as int),
                  role: Value(row['role'] as int),
                  durationMinutes: Value(row['duration_minutes'] as int),
                ),
              );
        }

        for (final row in instructionTimesRows) {
          await db
              .into(db.instructionTimesTable)
              .insert(
                InstructionTimesTableCompanion(
                  id: Value(row['id'] as String),
                  flightId: Value(row['flight_id'] as String),
                  category: Value(row['category'] as int),
                  durationMinutes: Value(row['duration_minutes'] as int),
                ),
              );
        }

        for (final row in instrumentTimesRows) {
          await db
              .into(db.instrumentTimesTable)
              .insert(
                InstrumentTimesTableCompanion(
                  id: Value(row['id'] as String),
                  flightId: Value(row['flight_id'] as String),
                  navaids: Value(row['navaids'] as String?),
                  place: Value(row['place'] as String?),
                  actualMinutes: Value((row['actual_minutes'] as int?) ?? 0),
                  fstdMinutes: Value((row['fstd_minutes'] as int?) ?? 0),
                ),
              );
        }

        for (final row in landingsRows) {
          await db
              .into(db.landingsTable)
              .insert(
                LandingsTableCompanion(
                  id: Value(row['id'] as String),
                  flightId: Value(row['flight_id'] as String),
                  dayCount: Value((row['day_count'] as int?) ?? 0),
                  nightCount: Value((row['night_count'] as int?) ?? 0),
                ),
              );
        }

        for (final row in docsRows) {
          var origPath = (row['original_path'] as String?) ?? '';
          final baseName = p.basename(origPath);

          final docBytes = docFileMap[baseName] ?? docFileMap[origPath];
          if (docBytes != null) {
            final ext = p.extension(origPath).replaceAll('.', '').toLowerCase();
            final mime = ext == 'png'
                ? 'image/png'
                : ext == 'pdf'
                ? 'application/pdf'
                : 'image/jpeg';
            origPath = 'data:$mime;base64,${base64Encode(docBytes)}';
          }

          await db
              .into(db.endorsementDocumentsTable)
              .insert(
                EndorsementDocumentsTableCompanion(
                  id: Value(row['id'] as String),
                  category: Value(row['category'] as String),
                  endorsementDate: Value(
                    _parseDateTime(row['endorsement_date']),
                  ),
                  pageNumber: Value(row['page_number'] as int?),
                  originalPath: Value(origPath),
                  pagesJson: Value(
                    _mapPagePaths(
                      row['pages_json'] as String?,
                      (path, index) => _restoreWebPagePath(path, docFileMap),
                    ),
                  ),
                  processedPath: Value(row['processed_path'] as String?),
                  thumbnailPath: Value(row['thumbnail_path'] as String?),
                  sha256: Value((row['sha256'] as String?) ?? ''),
                  capturedAt: Value(_parseDateTime(row['captured_at'])),
                  supersededBy: Value(row['superseded_by'] as String?),
                  supersedes: Value(row['supersedes'] as String?),
                  notes: Value(row['notes'] as String?),
                ),
              );
        }

        for (final row in modelEndorsementsRows) {
          await db
              .into(db.modelEndorsementsTable)
              .insert(
                ModelEndorsementsTableCompanion(
                  id: Value(row['id'] as String),
                  aircraftModelId: Value(row['aircraft_model_id'] as String),
                  pilotDate: Value(_parseDateTime(row['pilot_date'])),
                  instructorDate: Value(
                    row['instructor_date'] == null
                        ? null
                        : _parseDateTime(row['instructor_date']),
                  ),
                  instructorName: Value(row['instructor_name'] as String?),
                  instructorLicence: Value(
                    row['instructor_licence'] as String?,
                  ),
                  sourceDocumentId: Value(row['source_document_id'] as String?),
                  notes: Value(row['notes'] as String?),
                  createdAt: Value(_parseDateTime(row['created_at'])),
                ),
              );
        }

        await db.customStatement('PRAGMA foreign_keys = ON;');
      });
    } finally {
      sourceDb.close();
      sqlite.unregisterVirtualFileSystem(fs);
    }
  }

  // --- WEB DATABASE EXPORT ENGINE ---
  Future<Uint8List> _createWebDatabaseSnapshot() async {
    final sqlite = await getPlatformSqliteLoader().load();
    final fs = InMemoryFileSystem(
      name: 'mem_export_${DateTime.now().microsecondsSinceEpoch}',
    );
    sqlite.registerVirtualFileSystem(fs, makeDefault: false);
    final exportDb = sqlite.open('/export.sqlite', vfs: fs.name);

    try {
      exportDb.execute('''
        CREATE TABLE aircraft_models_table (
          id TEXT NOT NULL PRIMARY KEY,
          manufacturer TEXT NOT NULL,
          model TEXT NOT NULL,
          aircraft_class INTEGER NOT NULL,
          category INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        );
        CREATE TABLE flights_table (
          id TEXT NOT NULL PRIMARY KEY,
          date INTEGER NOT NULL,
          aircraft_model_id TEXT,
          registration TEXT NOT NULL,
          pic_name TEXT NOT NULL,
          remarks TEXT NOT NULL DEFAULT '',
          solo_cross_country INTEGER NOT NULL DEFAULT 0,
          fstd_actual_minutes INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
        CREATE TABLE flight_times_table (
          id TEXT NOT NULL PRIMARY KEY,
          flight_id TEXT NOT NULL,
          aircraft_class INTEGER NOT NULL,
          period INTEGER NOT NULL,
          role INTEGER NOT NULL,
          duration_minutes INTEGER NOT NULL
        );
        CREATE TABLE instruction_times_table (
          id TEXT NOT NULL PRIMARY KEY,
          flight_id TEXT NOT NULL,
          category INTEGER NOT NULL,
          duration_minutes INTEGER NOT NULL
        );
        CREATE TABLE instrument_times_table (
          id TEXT NOT NULL PRIMARY KEY,
          flight_id TEXT NOT NULL UNIQUE,
          navaids TEXT,
          place TEXT,
          actual_minutes INTEGER NOT NULL DEFAULT 0,
          fstd_minutes INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE landings_table (
          id TEXT NOT NULL PRIMARY KEY,
          flight_id TEXT NOT NULL UNIQUE,
          day_count INTEGER NOT NULL DEFAULT 0,
          night_count INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE endorsement_documents_table (
          id TEXT NOT NULL PRIMARY KEY,
          category TEXT NOT NULL,
          endorsement_date INTEGER NOT NULL,
          page_number INTEGER,
          original_path TEXT NOT NULL,
          processed_path TEXT,
          thumbnail_path TEXT,
          sha256 TEXT NOT NULL,
          captured_at INTEGER NOT NULL,
          superseded_by TEXT,
          supersedes TEXT,
          notes TEXT,
          pages_json TEXT
        );
        CREATE TABLE endorsement_corrections (id INTEGER PRIMARY KEY AUTOINCREMENT, endorsement_id TEXT NOT NULL, aircraft_model_id TEXT NOT NULL, removed_at TEXT NOT NULL, reason TEXT NOT NULL, snapshot TEXT NOT NULL);
        CREATE TABLE model_endorsements_table (
          id TEXT NOT NULL PRIMARY KEY,
          aircraft_model_id TEXT NOT NULL,
          pilot_date INTEGER NOT NULL,
          instructor_date INTEGER,
          instructor_name TEXT,
          instructor_licence TEXT,
          source_document_id TEXT,
          notes TEXT,
          created_at INTEGER NOT NULL
        );
      ''');

      final corrections = await db
          .customSelect('SELECT * FROM endorsement_corrections')
          .get();
      for (final row in corrections) {
        exportDb.execute(
          'INSERT INTO endorsement_corrections (endorsement_id, aircraft_model_id, removed_at, reason, snapshot) VALUES (?, ?, ?, ?, ?)',
          [
            row.data['endorsement_id'],
            row.data['aircraft_model_id'],
            row.data['removed_at'],
            row.data['reason'],
            row.data['snapshot'],
          ],
        );
      }
      final models = await db.select(db.aircraftModelsTable).get();
      for (final m in models) {
        exportDb.execute(
          'INSERT INTO aircraft_models_table VALUES (?, ?, ?, ?, ?, ?)',
          [
            m.id,
            m.manufacturer,
            m.model,
            m.aircraftClass,
            m.category,
            m.createdAt.millisecondsSinceEpoch ~/ 1000,
          ],
        );
      }

      final flights = await db.select(db.flightsTable).get();
      for (final f in flights) {
        exportDb.execute(
          'INSERT INTO flights_table VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            f.id,
            f.date.millisecondsSinceEpoch ~/ 1000,
            f.aircraftModelId,
            f.registration,
            f.picName,
            f.remarks,
            f.soloCrossCountry ? 1 : 0,
            f.fstdActualMinutes,
            f.createdAt.millisecondsSinceEpoch ~/ 1000,
            f.updatedAt.millisecondsSinceEpoch ~/ 1000,
          ],
        );
      }

      final ftimes = await db.select(db.flightTimesTable).get();
      for (final ft in ftimes) {
        exportDb.execute(
          'INSERT INTO flight_times_table VALUES (?, ?, ?, ?, ?, ?)',
          [
            ft.id,
            ft.flightId,
            ft.aircraftClass,
            ft.period,
            ft.role,
            ft.durationMinutes,
          ],
        );
      }

      final itimes = await db.select(db.instructionTimesTable).get();
      for (final it in itimes) {
        exportDb.execute(
          'INSERT INTO instruction_times_table VALUES (?, ?, ?, ?)',
          [it.id, it.flightId, it.category, it.durationMinutes],
        );
      }

      final instTimes = await db.select(db.instrumentTimesTable).get();
      for (final inst in instTimes) {
        exportDb.execute(
          'INSERT INTO instrument_times_table VALUES (?, ?, ?, ?, ?, ?)',
          [
            inst.id,
            inst.flightId,
            inst.navaids,
            inst.place,
            inst.actualMinutes,
            inst.fstdMinutes,
          ],
        );
      }

      final landings = await db.select(db.landingsTable).get();
      for (final l in landings) {
        exportDb.execute('INSERT INTO landings_table VALUES (?, ?, ?, ?)', [
          l.id,
          l.flightId,
          l.dayCount,
          l.nightCount,
        ]);
      }

      final docs = await db.select(db.endorsementDocumentsTable).get();
      for (final d in docs) {
        var origPath = d.originalPath;
        if (origPath.startsWith('data:')) {
          origPath = d.pagesJson == null
              ? 'endorsements/${d.id}.jpg'
              : 'endorsements/${d.id}_page1.jpg';
        }
        exportDb.execute(
          'INSERT INTO endorsement_documents_table VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            d.id,
            d.category,
            d.endorsementDate.millisecondsSinceEpoch ~/ 1000,
            d.pageNumber,
            origPath,
            d.processedPath,
            d.thumbnailPath,
            d.sha256,
            d.capturedAt.millisecondsSinceEpoch ~/ 1000,
            d.supersededBy,
            d.supersedes,
            d.notes,
            _mapPagePaths(
              d.pagesJson,
              (path, index) => path.startsWith('data:')
                  ? 'endorsements/${d.id}_page${index + 1}.jpg'
                  : path,
            ),
          ],
        );
      }

      final mEndorsements = await db.select(db.modelEndorsementsTable).get();
      for (final me in mEndorsements) {
        exportDb.execute(
          'INSERT INTO model_endorsements_table VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            me.id,
            me.aircraftModelId,
            me.pilotDate.millisecondsSinceEpoch ~/ 1000,
            me.instructorDate == null
                ? null
                : me.instructorDate!.millisecondsSinceEpoch ~/ 1000,
            me.instructorName,
            me.instructorLicence,
            me.sourceDocumentId,
            me.notes,
            me.createdAt.millisecondsSinceEpoch ~/ 1000,
          ],
        );
      }

      exportDb.execute('PRAGMA user_version = ${db.schemaVersion}');
      try {
        exportDb.execute('VACUUM INTO "/vacuum.sqlite";');
      } catch (_) {}

      final bytes =
          fs.fileData['/vacuum.sqlite'] ?? fs.fileData['/export.sqlite']!;
      return Uint8List.fromList(bytes);
    } finally {
      exportDb.close();
      sqlite.unregisterVirtualFileSystem(fs);
    }
  }

  // --- DOCUMENT COLLECTION HELPERS ---
  Future<List<ArchiveFileItem>> _collectNativeDocumentFiles(
    Directory docsDir,
  ) async {
    final documentFiles = <ArchiveFileItem>[];
    final endorsementsDir = Directory(p.join(docsDir.path, 'endorsements'));
    if (await endorsementsDir.exists()) {
      final entries = endorsementsDir.listSync();
      for (final entry in entries) {
        if (entry is File) {
          final fileName = p.basename(entry.path);
          final bytes = await entry.readAsBytes();
          documentFiles.add(
            ArchiveFileItem(path: 'endorsements/$fileName', bytes: bytes),
          );
        }
      }
    }
    return documentFiles;
  }

  Future<List<ArchiveFileItem>> _collectWebDocumentFiles() async {
    final documentFiles = <ArchiveFileItem>[];
    final docs = await db.select(db.endorsementDocumentsTable).get();
    for (final d in docs) {
      final paths = <String>[if (d.pagesJson == null) d.originalPath];
      final names = <String>[
        if (d.pagesJson == null) 'endorsements/${d.id}.jpg',
      ];
      _mapPagePaths(d.pagesJson, (path, index) {
        paths.add(path);
        names.add('endorsements/${d.id}_page${index + 1}.jpg');
        return path;
      });
      for (var i = 0; i < paths.length; i++) {
        final path = paths[i];
        if (!path.startsWith('data:')) {
          throw const BackupException(
            'Web document image is not locally available',
          );
        }
        final bytes = base64Decode(path.substring(path.indexOf(',') + 1));
        documentFiles.add(ArchiveFileItem(path: names[i], bytes: bytes));
      }
    }
    return documentFiles;
  }

  /// Rewrites only locations; ordered hashes and source page numbers remain unchanged.
  String? _mapPagePaths(String? manifest, String Function(String, int) map) {
    if (manifest == null) return null;
    final decoded = jsonDecode(manifest) as Map<String, dynamic>;
    final pages = decoded['pages'] as List<dynamic>;
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i] as Map<String, dynamic>;
      page['originalPath'] = map(page['originalPath'] as String, i);
    }
    return jsonEncode(decoded);
  }

  String _restoreWebPagePath(String path, Map<String, Uint8List> files) {
    if (path.startsWith('data:')) return path;
    final bytes = files[p.windows.basename(path)] ?? files[path];
    if (bytes == null) {
      throw const BackupException('Missing document page in backup');
    }
    final mime = p.extension(path).toLowerCase() == '.png'
        ? 'image/png'
        : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  List<Map<String, dynamic>> _readTable(
    CommonDatabase sourceDb,
    Set<String> availableTables,
    String preferredName,
    String alternateName,
  ) {
    final tableName = availableTables.contains(preferredName)
        ? preferredName
        : availableTables.contains(alternateName)
        ? alternateName
        : null;
    if (tableName == null) return const [];
    final result = sourceDb.select('SELECT * FROM "$tableName";');
    return result.map((r) {
      final map = <String, dynamic>{};
      for (final key in r.keys) {
        map[key] = r[key];
      }
      return map;
    }).toList();
  }

  DateTime _parseDateTime(dynamic val) {
    if (val is int) {
      final ms = val < 10000000000 ? val * 1000 : val;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    if (val is String) {
      final parsed = DateTime.tryParse(val);
      if (parsed != null) return parsed;
      final intVal = int.tryParse(val);
      if (intVal != null) {
        final ms = intVal < 10000000000 ? intVal * 1000 : intVal;
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      }
    }
    return DateTime.now().toUtc();
  }

  bool _parseBool(dynamic val) {
    if (val is bool) return val;
    if (val is int) return val != 0;
    if (val is String) return val.toLowerCase() == 'true' || val == '1';
    return false;
  }
}
