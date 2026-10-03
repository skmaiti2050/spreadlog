import 'dart:typed_data';
import 'package:aviation_logbook/features/backups/data/backup_settings_repository.dart';
import 'package:aviation_logbook/features/backups/data/google_auth_service.dart';
import 'package:aviation_logbook/features/backups/data/transports/gmail_backup_transport.dart';
import 'package:aviation_logbook/features/backups/data/transports/google_drive_backup_transport.dart';
import 'package:aviation_logbook/features/backups/domain/backup_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Google Cloud Transports & Settings Tests', () {
    test('GoogleDriveBackupItem model assigns properties accurately', () {
      final now = DateTime.now();
      final item = GoogleDriveBackupItem(
        id: 'file_123',
        name: 'spreadlog_backup.spbackup',
        sizeBytes: 1048576,
        createdTime: now,
        modifiedTime: now,
      );

      expect(item.id, equals('file_123'));
      expect(item.name, equals('spreadlog_backup.spbackup'));
      expect(item.sizeBytes, equals(1048576));
      expect(item.createdTime, equals(now));
      expect(item.modifiedTime, equals(now));
    });

    test('GoogleDriveBackupTransport throws BackupTransportException when unauthenticated', () async {
      final authService = GoogleAuthService();
      final transport = GoogleDriveBackupTransport(authService);

      expect(
        () async => transport.dispatchBackup(
          encryptedBytes: Uint8List.fromList([1, 2, 3]),
          suggestedFileName: 'test.spbackup',
        ),
        throwsA(isA<BackupTransportException>()),
      );
    });

    test('GmailBackupTransport throws BackupTransportException when unauthenticated', () async {
      final authService = GoogleAuthService();
      final transport = GmailBackupTransport(authService);

      expect(
        () async => transport.dispatchBackup(
          encryptedBytes: Uint8List.fromList([1, 2, 3]),
          suggestedFileName: 'test.spbackup',
          recipientEmail: 'pilot@example.com',
        ),
        throwsA(isA<BackupTransportException>()),
      );
    });

    test('BackupSettings copyWith preserves and updates Google sync fields', () {
      const initial = BackupSettings(
        hasMasterPassphrase: true,
        autoBackupEnabled: false,
        autoSyncGoogleDrive: false,
        preferredBackupMethod: 'local',
        googleAccountEmail: null,
      );

      final updated = initial.copyWith(
        autoSyncGoogleDrive: true,
        preferredBackupMethod: 'drive',
        googleAccountEmail: 'captain@spreadlog.com',
      );

      expect(updated.hasMasterPassphrase, isTrue);
      expect(updated.autoSyncGoogleDrive, isTrue);
      expect(updated.preferredBackupMethod, equals('drive'));
      expect(updated.googleAccountEmail, equals('captain@spreadlog.com'));
    });

    test('GmailBackupTransport defines 20 MB ceiling for direct attachments before Drive link', () {
      expect(GmailBackupTransport.maxDirectAttachmentBytes, equals(20 * 1024 * 1024));
    });
  });
}
