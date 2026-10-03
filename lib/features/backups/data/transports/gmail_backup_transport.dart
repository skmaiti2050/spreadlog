import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import '../../domain/backup_exceptions.dart';
import '../../domain/backup_transport.dart';
import '../google_auth_service.dart';
import 'google_drive_backup_transport.dart';

/// Backup transport dispatching encrypted backups directly to the pilot's Gmail address
/// using the official Google REST Gmail API without SMTP credentials or app passwords.
///
/// If the backup archive exceeds ~20 MB (which becomes >25 MB after base64 MIME encoding),
/// it automatically uploads the backup to the pilot's Google Drive and sends an email with the
/// direct Google Drive file link, exactly mimicking Gmail's web & mobile behavior.
class GmailBackupTransport implements BackupTransport {
  /// Gmail enforces a 25 MB message threshold.
  /// Base64 encoding inflates binary bytes by 33%, meaning archives above ~20 MB
  /// exceed the 25 MB MIME ceiling.
  static const int maxDirectAttachmentBytes = 20 * 1024 * 1024; // 20 MB

  final GoogleAuthService _authService;
  final GoogleDriveBackupTransport? _driveTransport;

  GmailBackupTransport(this._authService, [this._driveTransport]);

  @override
  String get name => 'Gmail API Transport';

  @override
  Future<void> dispatchBackup({
    required Uint8List encryptedBytes,
    required String suggestedFileName,
    String? recipientEmail,
  }) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      if (client == null) {
        throw const BackupTransportException(
          'Google account is not connected or Gmail permissions were not granted. Please sign in and allow access.',
        );
      }

      final targetEmail = recipientEmail ?? _authService.currentUser?.email;
      if (targetEmail == null || targetEmail.isEmpty) {
        throw const BackupTransportException('No recipient email specified for Gmail dispatch.');
      }

      final gmailApi = gmail.GmailApi(client);

      // Check if file exceeds the 25 MB Gmail attachment limit
      if (encryptedBytes.length > maxDirectAttachmentBytes) {
        // Automatically upload to Google Drive and attach link in email
        final driveTransport = _driveTransport ?? GoogleDriveBackupTransport(_authService);
        final fileId = await driveTransport.uploadBackupFile(
          encryptedBytes: encryptedBytes,
          suggestedFileName: suggestedFileName,
        );

        final driveUrl = 'https://drive.google.com/file/d/$fileId/view';
        final sizeMb = (encryptedBytes.length / (1024 * 1024)).toStringAsFixed(1);

        final buffer = StringBuffer()
          ..writeln('To: $targetEmail')
          ..writeln('Subject: Spreadlog Encrypted Backup ($suggestedFileName) [Google Drive Attachment]')
          ..writeln('MIME-Version: 1.0')
          ..writeln('Content-Type: text/plain; charset="UTF-8"')
          ..writeln('Content-Transfer-Encoding: 7bit')
          ..writeln()
          ..writeln('Captain,')
          ..writeln()
          ..writeln('Your AES-256 encrypted Spreadlog pilot logbook backup archive is $sizeMb MB in size.')
          ..writeln('Because this exceeds the standard 25 MB Gmail direct attachment threshold,')
          ..writeln('your backup has been securely attached via your Google Drive:')
          ..writeln()
          ..writeln('Google Drive Link: $driveUrl')
          ..writeln()
          ..writeln('Archive Name: $suggestedFileName')
          ..writeln('Archive Size: ${encryptedBytes.length} bytes ($sizeMb MB)')
          ..writeln('Exported on: ${DateTime.now().toUtc().toIso8601String()}')
          ..writeln()
          ..writeln('Keep this file safe. You can download or restore this backup directly inside the Spreadlog app.');

        final rawBytes = utf8.encode(buffer.toString());
        final rawBase64Url = base64Url.encode(rawBytes).replaceAll('=', '');

        final message = gmail.Message()..raw = rawBase64Url;
        await gmailApi.users.messages.send(message, 'me');
        return;
      }

      // Standard direct attachment (<20 MB binary = <25 MB MIME)
      final boundary = '----=_SpreadlogBoundary_${DateTime.now().millisecondsSinceEpoch}';
      final fileBase64 = base64.encode(encryptedBytes);

      final buffer = StringBuffer()
        ..writeln('To: $targetEmail')
        ..writeln('Subject: Spreadlog Encrypted Backup ($suggestedFileName)')
        ..writeln('MIME-Version: 1.0')
        ..writeln('Content-Type: multipart/mixed; boundary="$boundary"')
        ..writeln()
        ..writeln('--$boundary')
        ..writeln('Content-Type: text/plain; charset="UTF-8"')
        ..writeln('Content-Transfer-Encoding: 7bit')
        ..writeln()
        ..writeln('Captain,')
        ..writeln()
        ..writeln('Attached is your AES-256 encrypted Spreadlog pilot logbook backup archive:')
        ..writeln('Archive Name: $suggestedFileName')
        ..writeln('Archive Size: ${encryptedBytes.length} bytes')
        ..writeln('Exported on: ${DateTime.now().toUtc().toIso8601String()}')
        ..writeln()
        ..writeln('Keep this file safe. You can restore this file anytime directly within the Spreadlog app.')
        ..writeln()
        ..writeln('--$boundary')
        ..writeln('Content-Type: application/octet-stream; name="$suggestedFileName"')
        ..writeln('Content-Disposition: attachment; filename="$suggestedFileName"')
        ..writeln('Content-Transfer-Encoding: base64')
        ..writeln()
        ..writeln(fileBase64)
        ..writeln('--$boundary--');

      final rawBytes = utf8.encode(buffer.toString());
      final rawBase64Url = base64Url.encode(rawBytes).replaceAll('=', '');

      final message = gmail.Message()..raw = rawBase64Url;

      await gmailApi.users.messages.send(message, 'me');
    } catch (e) {
      if (e is BackupTransportException) rethrow;
      debugPrint('Gmail API dispatch error: $e');
      throw BackupTransportException('Failed to dispatch backup via Gmail API: $e', e);
    }
  }
}
