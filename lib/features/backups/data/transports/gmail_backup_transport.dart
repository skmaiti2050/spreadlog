import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import '../../domain/backup_exceptions.dart';
import '../../domain/backup_transport.dart';
import '../google_auth_service.dart';

/// Backup transport dispatching encrypted backups directly to the pilot's Gmail address
/// using the official Google REST Gmail API without SMTP credentials or app passwords.
class GmailBackupTransport implements BackupTransport {
  final GoogleAuthService _authService;

  GmailBackupTransport(this._authService);

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
          'Google account is not signed in. Please sign in to Google first.',
        );
      }

      final targetEmail = recipientEmail ?? _authService.currentUser?.email;
      if (targetEmail == null || targetEmail.isEmpty) {
        throw const BackupTransportException('No recipient email specified for Gmail dispatch.');
      }

      final gmailApi = gmail.GmailApi(client);

      // Create RFC 2822 multi-part MIME payload
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
