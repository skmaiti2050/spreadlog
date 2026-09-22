import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/backup_exceptions.dart';
import '../../domain/backup_transport.dart';

/// Backup transport leveraging native operating system sharing mechanisms (AirDrop, Google Drive,
/// local file save, email, messaging apps) via [SharePlus].
class ShareBackupTransport implements BackupTransport {
  @override
  String get name => 'OS Share / Export';

  @override
  Future<void> dispatchBackup({
    required Uint8List encryptedBytes,
    required String suggestedFileName,
    String? recipientEmail,
  }) async {
    try {
      if (kIsWeb) {
        // Web export via SharePlus XFile
        final xfile = XFile.fromData(
          encryptedBytes,
          name: suggestedFileName,
          mimeType: 'application/octet-stream',
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [xfile],
            subject: 'Spreadlog Encrypted Backup',
            text: 'Encrypted pilot logbook backup archive ($suggestedFileName).',
          ),
        );
        return;
      }

      // Native export
      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory(p.join(tempDir.path, 'backups_export'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final file = File(p.join(backupDir.path, suggestedFileName));
      await file.writeAsBytes(encryptedBytes, flush: true);

      final xfile = XFile(file.path, mimeType: 'application/octet-stream');
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xfile],
          subject: 'Spreadlog Encrypted Backup',
          text: 'Encrypted pilot logbook backup archive ($suggestedFileName).',
        ),
      );

      if (result.status == ShareResultStatus.dismissed) {
        // User dismissed the sheet, still valid
      }
    } catch (e) {
      throw BackupTransportException('Failed to export backup via OS share: $e', e);
    }
  }
}
