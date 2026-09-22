import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../endorsements/domain/document_hasher.dart';
import '../domain/backup_exceptions.dart';
import '../domain/backup_manifest.dart';

/// Archive entry representing a file to be zipped or extracted.
class ArchiveFileItem {
  final String path;
  final Uint8List bytes;

  const ArchiveFileItem({required this.path, required this.bytes});
}

/// Service responsible for packaging files into a standard ZIP archive with a signed manifest
/// and unpacking archives with tamper-evident SHA-256 integrity validation.
class BackupArchiveService {
  final DocumentHasher _hasher;

  BackupArchiveService({DocumentHasher? hasher})
      : _hasher = hasher ?? DocumentHasher();

  /// Packs the [databaseBytes] and [documentFiles] into a ZIP archive containing `manifest.json`.
  Future<Uint8List> createZipArchive({
    required Uint8List databaseBytes,
    required List<ArchiveFileItem> documentFiles,
    required int flightCount,
    required int aircraftModelCount,
    required int schemaVersion,
    String appVersion = '1.0.0',
    DateTime? createdAt,
  }) async {
    final archive = Archive();
    final now = createdAt ?? DateTime.now().toUtc();

    // 1. Hash and add SQLite Database file
    final dbSha256 = await _hasher.computeSha256(databaseBytes);
    const dbRelativePath = 'database/app_database.sqlite';
    archive.addFile(ArchiveFile(
      dbRelativePath,
      databaseBytes.length,
      databaseBytes,
    ));

    final dbEntry = BackupFileEntry(
      relativePath: dbRelativePath,
      sha256: dbSha256,
      sizeBytes: databaseBytes.length,
    );

    // 2. Hash and add Endorsement Document files
    final docEntries = <BackupFileEntry>[];
    for (final doc in documentFiles) {
      final docSha256 = await _hasher.computeSha256(doc.bytes);
      archive.addFile(ArchiveFile(
        doc.path,
        doc.bytes.length,
        doc.bytes,
      ));
      docEntries.add(BackupFileEntry(
        relativePath: doc.path,
        sha256: docSha256,
        sizeBytes: doc.bytes.length,
      ));
    }

    // 3. Assemble and add manifest.json
    final manifest = BackupManifest(
      manifestVersion: BackupManifest.currentManifestVersion,
      createdAt: now,
      appVersion: appVersion,
      schemaVersion: schemaVersion,
      databaseEntry: dbEntry,
      documentEntries: docEntries,
      flightCount: flightCount,
      documentCount: docEntries.length,
      aircraftModelCount: aircraftModelCount,
    );

    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    archive.addFile(ArchiveFile(
      'manifest.json',
      manifestBytes.length,
      manifestBytes,
    ));

    // 4. Encode to ZIP format
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// Extracts and validates an in-memory ZIP archive.
  ///
  /// Verifies that every file described in `manifest.json` matches its SHA-256 checksum.
  /// Throws [CorruptedBackupException] if the manifest is missing, corrupt, or if any hash mismatches.
  Future<ExtractedBackup> unpackAndValidateZip(Uint8List zipBytes) async {
    final zipDecoder = ZipDecoder();
    final Archive archive;
    try {
      archive = zipDecoder.decodeBytes(zipBytes);
    } catch (e) {
      throw CorruptedBackupException('Invalid ZIP archive structure: $e');
    }

    // 1. Locate manifest.json
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const CorruptedBackupException('manifest.json is missing from the backup archive.');
    }

    final manifestContent = utf8.decode(manifestFile.content as List<int>);
    final BackupManifest manifest;
    try {
      manifest = BackupManifest.fromJson(jsonDecode(manifestContent) as Map<String, dynamic>);
    } catch (e) {
      throw CorruptedBackupException('Corrupted manifest.json format: $e');
    }

    // 2. Locate and verify Database
    final dbFile = archive.findFile(manifest.databaseEntry.relativePath);
    if (dbFile == null) {
      throw CorruptedBackupException(
        'Database file ${manifest.databaseEntry.relativePath} is missing from the archive.',
        failedFile: manifest.databaseEntry.relativePath,
      );
    }
    final dbBytes = Uint8List.fromList(dbFile.content as List<int>);
    final isDbValid = await _hasher.verifySha256(dbBytes, manifest.databaseEntry.sha256);
    if (!isDbValid) {
      throw CorruptedBackupException(
        'Database integrity check failed (SHA-256 mismatch).',
        failedFile: manifest.databaseEntry.relativePath,
      );
    }

    // 3. Locate and verify Endorsement Document files
    final extractedDocuments = <ArchiveFileItem>[];
    for (final docEntry in manifest.documentEntries) {
      final docFile = archive.findFile(docEntry.relativePath);
      if (docFile == null) {
        throw CorruptedBackupException(
          'Document file ${docEntry.relativePath} is missing from the archive.',
          failedFile: docEntry.relativePath,
        );
      }
      final docBytes = Uint8List.fromList(docFile.content as List<int>);
      final isDocValid = await _hasher.verifySha256(docBytes, docEntry.sha256);
      if (!isDocValid) {
        throw CorruptedBackupException(
          'Document integrity check failed for ${docEntry.relativePath} (SHA-256 mismatch).',
          failedFile: docEntry.relativePath,
        );
      }
      extractedDocuments.add(ArchiveFileItem(
        path: docEntry.relativePath,
        bytes: docBytes,
      ));
    }

    return ExtractedBackup(
      manifest: manifest,
      databaseBytes: dbBytes,
      documentFiles: extractedDocuments,
    );
  }
}

/// Holds validated components unpacked from a backup archive.
class ExtractedBackup {
  final BackupManifest manifest;
  final Uint8List databaseBytes;
  final List<ArchiveFileItem> documentFiles;

  const ExtractedBackup({
    required this.manifest,
    required this.databaseBytes,
    required this.documentFiles,
  });
}
