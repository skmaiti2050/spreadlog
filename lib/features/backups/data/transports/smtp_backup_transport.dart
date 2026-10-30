import 'dart:typed_data';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../../domain/backup_exceptions.dart';
import '../../domain/backup_transport.dart';

/// Configuration required to dispatch backups via an SMTP server.
class SmtpConfig {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool useTls;
  final String senderEmail;
  final String? recoveryEmail;

  const SmtpConfig({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.senderEmail,
    this.useTls = true,
    this.recoveryEmail,
  });
}

/// Backup transport for emailing encrypted `.spbackup` archives to the pilot's primary
/// and recovery email addresses via SMTP.
class SmtpBackupTransport implements BackupTransport {
  final SmtpConfig config;

  SmtpBackupTransport(this.config);

  @override
  String get name => 'SMTP Email Transport';

  @override
  Future<void> dispatchBackup({
    required Uint8List encryptedBytes,
    required String suggestedFileName,
    String? recipientEmail,
  }) async {
    final targetRecipient = recipientEmail ?? config.senderEmail;
    if (targetRecipient.isEmpty) {
      throw const BackupTransportException(
        'No recipient email specified for SMTP backup.',
      );
    }

    try {
      final smtpServer = SmtpServer(
        config.host,
        port: config.port,
        ssl: config.port == 465,
        allowInsecure: !config.useTls && config.port != 465,
        username: config.username,
        password: config.password,
      );

      final message = Message()
        ..from = Address(config.senderEmail, 'Spreadlog Backup')
        ..recipients.add(targetRecipient)
        ..subject = 'Spreadlog Encrypted Logbook Backup - $suggestedFileName'
        ..text =
            'Attached is your automated, AES-256-GCM encrypted Spreadlog backup ($suggestedFileName).\n\n'
            'Keep your master passphrase safe. You will need it to restore this logbook archive.'
        ..attachments.add(
          StreamAttachment(
            Stream.value(encryptedBytes),
            'application/octet-stream',
            fileName: suggestedFileName,
          ),
        );

      if (config.recoveryEmail != null && config.recoveryEmail!.isNotEmpty) {
        message.ccRecipients.add(config.recoveryEmail!);
      }

      await send(message, smtpServer);
    } on MailerException catch (e) {
      // e.g. "Invalid message." alone hides which address or login failed.
      final details = e.problems.map((p) => p.msg).join('; ');
      throw BackupTransportException(
        'SMTP server refused the backup: '
        '${details.isEmpty ? e.message : details}',
        e,
      );
    } catch (e) {
      throw BackupTransportException('Failed to send backup via SMTP: $e', e);
    }
  }
}
