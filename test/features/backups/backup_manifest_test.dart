import 'package:aviation_logbook/features/backups/domain/backup_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupManifest Domain Entity', () {
    test('serializes to and from JSON accurately', () {
      final now = DateTime.utc(2026, 9, 22, 12, 0, 0);
      final manifest = BackupManifest(
        manifestVersion: 1,
        createdAt: now,
        appVersion: '1.0.0',
        schemaVersion: 3,
        databaseEntry: const BackupFileEntry(
          relativePath: 'database/app_database.sqlite',
          sha256: 'abcdef1234567890',
          sizeBytes: 40960,
        ),
        documentEntries: const [
          BackupFileEntry(
            relativePath: 'endorsements/doc-1.jpg',
            sha256: '112233445566',
            sizeBytes: 152000,
          ),
          BackupFileEntry(
            relativePath: 'endorsements/doc-2.jpg',
            sha256: 'aabbccddeeff',
            sizeBytes: 180000,
          ),
        ],
        flightCount: 42,
        documentCount: 2,
        aircraftModelCount: 7,
      );

      final json = manifest.toJson();
      final restored = BackupManifest.fromJson(json);

      expect(restored.manifestVersion, equals(1));
      expect(restored.createdAt, equals(now));
      expect(restored.appVersion, equals('1.0.0'));
      expect(restored.schemaVersion, equals(3));
      expect(restored.databaseEntry.relativePath, equals('database/app_database.sqlite'));
      expect(restored.databaseEntry.sha256, equals('abcdef1234567890'));
      expect(restored.databaseEntry.sizeBytes, equals(40960));
      expect(restored.documentEntries.length, equals(2));
      expect(restored.documentEntries.first.relativePath, equals('endorsements/doc-1.jpg'));
      expect(restored.flightCount, equals(42));
      expect(restored.documentCount, equals(2));
      expect(restored.aircraftModelCount, equals(7));
      expect(restored.totalSizeBytes, equals(40960 + 152000 + 180000));
    });

    test('BackupFileEntry equality and hashCode', () {
      const a = BackupFileEntry(
        relativePath: 'test.jpg',
        sha256: 'hash1',
        sizeBytes: 100,
      );
      const b = BackupFileEntry(
        relativePath: 'test.jpg',
        sha256: 'hash1',
        sizeBytes: 100,
      );
      const c = BackupFileEntry(
        relativePath: 'test2.jpg',
        sha256: 'hash2',
        sizeBytes: 200,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
