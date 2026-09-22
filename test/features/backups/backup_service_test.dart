import 'dart:io';

import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/backups/data/backup_archive_service.dart';
import 'package:aviation_logbook/features/backups/data/backup_service.dart';
import 'package:aviation_logbook/features/backups/domain/backup_encryptor.dart';
import 'package:aviation_logbook/features/backups/domain/backup_exceptions.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupService Integration Tests', () {
    late AppDatabase db;
    late BackupService backupService;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('backup_test_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async => tempDir.path,
      );

      db = AppDatabase(NativeDatabase.memory());
      // Seed initial models
      await db.aircraftDao.getAllModels();

      final fastEncryptor = BackupEncryptor(
        kdf: Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: 1000, // fast iterations for test
          bits: 256,
        ),
      );

      backupService = BackupService(
        db: db,
        encryptor: fastEncryptor,
        archiveService: BackupArchiveService(),
      );
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('inspects created backup and validates manifest counts', () async {
      const passphrase = 'PilotSafeSecret2026!';

      // Create backup bytes
      final zipBytes = await BackupArchiveService().createZipArchive(
        databaseBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
        documentFiles: [
          ArchiveFileItem(
            path: 'endorsements/test_stamp.jpg',
            bytes: Uint8List.fromList([10, 20, 30]),
          ),
        ],
        flightCount: 5,
        aircraftModelCount: 2,
        schemaVersion: 3,
      );

      final fastEncryptor = BackupEncryptor(
        kdf: Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: 1000,
          bits: 256,
        ),
      );

      final encryptedBackup = await fastEncryptor.encrypt(
        clearBytes: zipBytes,
        passphrase: passphrase,
      );

      final inspection = await backupService.inspectBackup(
        backupBytes: encryptedBackup,
        passphrase: passphrase,
      );

      expect(inspection.isIntegrityVerified, isTrue);
      expect(inspection.manifest.flightCount, equals(5));
      expect(inspection.manifest.aircraftModelCount, equals(2));
      expect(inspection.manifest.documentCount, equals(1));
      expect(inspection.manifest.schemaVersion, equals(3));
    });

    test('inspectBackup throws InvalidPassphraseException when passphrase is wrong', () async {
      const correctPass = 'CorrectPass123';
      const wrongPass = 'WrongPass456';

      final zipBytes = await BackupArchiveService().createZipArchive(
        databaseBytes: Uint8List.fromList([1, 2, 3]),
        documentFiles: [],
        flightCount: 0,
        aircraftModelCount: 0,
        schemaVersion: 3,
      );

      final fastEncryptor = BackupEncryptor(
        kdf: Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: 1000,
          bits: 256,
        ),
      );

      final encrypted = await fastEncryptor.encrypt(
        clearBytes: zipBytes,
        passphrase: correctPass,
      );

      expect(
        () async => await backupService.inspectBackup(
          backupBytes: encrypted,
          passphrase: wrongPass,
        ),
        throwsA(isA<InvalidPassphraseException>()),
      );
    });

    test('restoreBackup with preExtractedBackup bypasses redundant decryption and returns manifest', () async {
      const passphrase = 'PilotSafeSecret2026!';

      final zipBytes = await BackupArchiveService().createZipArchive(
        databaseBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
        documentFiles: [
          ArchiveFileItem(
            path: 'endorsements/stamp.jpg',
            bytes: Uint8List.fromList([10, 20]),
          ),
        ],
        flightCount: 3,
        aircraftModelCount: 1,
        schemaVersion: 3,
      );

      final fastEncryptor = BackupEncryptor(
        kdf: Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: 1000,
          bits: 256,
        ),
      );

      final encrypted = await fastEncryptor.encrypt(
        clearBytes: zipBytes,
        passphrase: passphrase,
      );

      final inspection = await backupService.inspectBackup(
        backupBytes: encrypted,
        passphrase: passphrase,
      );

      expect(inspection.extractedBackup, isNotNull);

      final manifest = await backupService.restoreBackup(
        backupBytes: encrypted,
        passphrase: passphrase,
        preExtractedBackup: inspection.extractedBackup,
      );

      expect(manifest.flightCount, equals(3));
      expect(manifest.documentCount, equals(1));
    });
  });
}

