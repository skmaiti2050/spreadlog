import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:aviation_logbook/features/backups/data/backup_archive_service.dart';
import 'package:aviation_logbook/features/backups/domain/backup_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupArchiveService Integration', () {
    late BackupArchiveService archiveService;

    setUp(() {
      archiveService = BackupArchiveService();
    });

    test('creates and unpacks ZIP archive with valid checksums', () async {
      final dbBytes = Uint8List.fromList(utf8.encode('SIMULATED_SQLITE_DATABASE_HEADER_DATA'));
      final doc1Bytes = Uint8List.fromList(utf8.encode('STAMP_IMAGE_1_BYTES'));
      final doc2Bytes = Uint8List.fromList(utf8.encode('STAMP_IMAGE_2_BYTES'));

      final zipData = await archiveService.createZipArchive(
        databaseBytes: dbBytes,
        documentFiles: [
          ArchiveFileItem(path: 'endorsements/stamp1.jpg', bytes: doc1Bytes),
          ArchiveFileItem(path: 'endorsements/stamp2.jpg', bytes: doc2Bytes),
        ],
        flightCount: 15,
        aircraftModelCount: 3,
        schemaVersion: 3,
      );

      expect(zipData.isNotEmpty, isTrue);

      final extracted = await archiveService.unpackAndValidateZip(zipData);

      expect(extracted.manifest.flightCount, equals(15));
      expect(extracted.manifest.aircraftModelCount, equals(3));
      expect(extracted.manifest.schemaVersion, equals(3));
      expect(extracted.manifest.documentCount, equals(2));
      expect(extracted.databaseBytes, equals(dbBytes));
      expect(extracted.documentFiles.length, equals(2));
      expect(extracted.documentFiles[0].path, equals('endorsements/stamp1.jpg'));
      expect(extracted.documentFiles[0].bytes, equals(doc1Bytes));
      expect(extracted.documentFiles[1].path, equals('endorsements/stamp2.jpg'));
      expect(extracted.documentFiles[1].bytes, equals(doc2Bytes));
    });

    test('fails unpackAndValidateZip when document content has been modified', () async {
      final dbBytes = Uint8List.fromList(utf8.encode('SQLITE_DATA'));
      final docBytes = Uint8List.fromList(utf8.encode('AUTHENTIC_IMAGE'));

      final zipData = await archiveService.createZipArchive(
        databaseBytes: dbBytes,
        documentFiles: [
          ArchiveFileItem(path: 'endorsements/doc.jpg', bytes: docBytes),
        ],
        flightCount: 1,
        aircraftModelCount: 1,
        schemaVersion: 3,
      );

      // Tamper with the uncompressed file inside the zip
      final decoder = ZipDecoder();
      final decodedArchive = decoder.decodeBytes(zipData);

      final tamperedArchive = Archive();
      for (final file in decodedArchive.files) {
        if (file.name == 'endorsements/doc.jpg') {
          // Alter content without updating manifest
          final modifiedBytes = utf8.encode('TAMPERED_IMAGE');
          tamperedArchive.addFile(ArchiveFile(file.name, modifiedBytes.length, modifiedBytes));
        } else {
          tamperedArchive.addFile(file);
        }
      }

      final tamperedZip = Uint8List.fromList(ZipEncoder().encode(tamperedArchive));

      expect(
        () async => await archiveService.unpackAndValidateZip(tamperedZip),
        throwsA(isA<CorruptedBackupException>().having(
          (e) => e.failedFile,
          'failedFile',
          equals('endorsements/doc.jpg'),
        )),
      );
    });

    test('fails unpackAndValidateZip when manifest.json is missing', () async {
      final emptyArchive = Archive();
      emptyArchive.addFile(ArchiveFile('dummy.txt', 5, utf8.encode('hello')));
      final zipBytes = Uint8List.fromList(ZipEncoder().encode(emptyArchive));

      expect(
        () async => await archiveService.unpackAndValidateZip(zipBytes),
        throwsA(isA<CorruptedBackupException>()),
      );
    });
  });
}
