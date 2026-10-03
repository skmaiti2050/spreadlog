import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../domain/backup_exceptions.dart';
import '../../domain/backup_transport.dart';
import '../google_auth_service.dart';

/// Item representing an encrypted backup stored in the pilot's Google Drive.
class GoogleDriveBackupItem {
  final String id;
  final String name;
  final int sizeBytes;
  final DateTime? createdTime;
  final DateTime? modifiedTime;

  const GoogleDriveBackupItem({
    required this.id,
    required this.name,
    required this.sizeBytes,
    this.createdTime,
    this.modifiedTime,
  });
}

/// Backup transport uploading and managing encrypted `.spreadlog` archives in Google Drive.
class GoogleDriveBackupTransport implements BackupTransport {
  static const String folderName = 'Spreadlog Aviation Backups';

  final GoogleAuthService _authService;

  GoogleDriveBackupTransport(this._authService);

  @override
  String get name => 'Google Drive Cloud Sync';

  Future<drive.DriveApi> _getDriveApi() async {
    final client = await _authService.getAuthenticatedClient();
    if (client == null) {
      throw const BackupTransportException(
        'Google account is not connected or Drive permissions were not granted. Please sign in and allow access.',
      );
    }
    return drive.DriveApi(client);
  }

  /// Finds or creates the dedicated Spreadlog folder in Google Drive.
  Future<String> _getOrCreateFolder(drive.DriveApi api) async {
    try {
      const query =
          "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final searchResult = await api.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (searchResult.files != null && searchResult.files!.isNotEmpty) {
        return searchResult.files!.first.id!;
      }

      final folderMetadata = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..description = 'Encrypted Spreadlog pilot logbook backup archives.';

      final createdFolder = await api.files.create(folderMetadata);
      return createdFolder.id!;
    } catch (e) {
      debugPrint('Failed to get or create Google Drive folder: $e');
      throw BackupTransportException('Could not create Google Drive folder: $e', e);
    }
  }

  /// Uploads backup file to Google Drive and returns the created file ID.
  Future<String> uploadBackupFile({
    required Uint8List encryptedBytes,
    required String suggestedFileName,
  }) async {
    try {
      final api = await _getDriveApi();
      final folderId = await _getOrCreateFolder(api);

      final fileMetadata = drive.File()
        ..name = suggestedFileName
        ..parents = [folderId]
        ..mimeType = 'application/octet-stream'
        ..description =
            'Encrypted Spreadlog Aviation Logbook Archive (${DateTime.now().toUtc().toIso8601String()})';

      final media = drive.Media(
        Stream.value(encryptedBytes),
        encryptedBytes.length,
      );

      final created = await api.files.create(
        fileMetadata,
        uploadMedia: media,
      );
      return created.id ?? '';
    } catch (e) {
      if (e is BackupTransportException) rethrow;
      throw BackupTransportException('Failed to upload backup to Google Drive: $e', e);
    }
  }

  @override
  Future<void> dispatchBackup({
    required Uint8List encryptedBytes,
    required String suggestedFileName,
    String? recipientEmail,
  }) async {
    await uploadBackupFile(
      encryptedBytes: encryptedBytes,
      suggestedFileName: suggestedFileName,
    );
  }

  /// Lists all `.spreadlog` encrypted backup archives stored in Google Drive.
  Future<List<GoogleDriveBackupItem>> listBackups() async {
    try {
      final api = await _getDriveApi();
      final folderId = await _getOrCreateFolder(api);

      final query = "'$folderId' in parents and trashed = false";
      final result = await api.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name, size, createdTime, modifiedTime)',
        orderBy: 'createdTime desc',
      );

      final files = result.files ?? [];
      return files.map((f) {
        return GoogleDriveBackupItem(
          id: f.id ?? '',
          name: f.name ?? 'spreadlog_backup.spreadlog',
          sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
          createdTime: f.createdTime,
          modifiedTime: f.modifiedTime,
        );
      }).toList();
    } catch (e) {
      debugPrint('Failed to list Google Drive backups: $e');
      throw BackupTransportException('Failed to list backups from Google Drive: $e', e);
    }
  }

  /// Downloads the encrypted bytes of a specific backup from Google Drive.
  Future<Uint8List> downloadBackup(String fileId) async {
    try {
      final api = await _getDriveApi();
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Failed to download Google Drive backup: $e');
      throw BackupTransportException('Failed to download backup from Google Drive: $e', e);
    }
  }

  /// Deletes a specific backup from Google Drive.
  Future<void> deleteBackup(String fileId) async {
    try {
      final api = await _getDriveApi();
      await api.files.delete(fileId);
    } catch (e) {
      debugPrint('Failed to delete Google Drive backup: $e');
      throw BackupTransportException('Failed to delete backup from Google Drive: $e', e);
    }
  }
}
