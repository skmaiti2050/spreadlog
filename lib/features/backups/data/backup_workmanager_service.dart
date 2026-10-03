import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/database/app_database.dart';
import 'backup_service.dart';
import 'backup_settings_repository.dart';
import 'google_auth_service.dart';
import 'transports/google_drive_backup_transport.dart';
import 'transports/smtp_backup_transport.dart';

/// Unique task identifier for periodic automated backups.
const String periodicBackupTaskKey = 'com.example.aviation_logbook.periodic_backup';

/// Callback dispatcher invoked by Android/iOS background Workmanager.
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final settingsRepo = BackupSettingsRepository();
      final settings = await settingsRepo.loadSettings();

      // Check if auto-sync to Google Drive is enabled
      if (settings.autoSyncGoogleDrive) {
        final authService = GoogleAuthService();
        final account = await authService.signInSilently();
        if (account != null) {
          final masterPass = await settingsRepo.getMasterPassphrase();
          if (masterPass != null && masterPass.isNotEmpty) {
            final db = AppDatabase();
            try {
              final backupService = BackupService(db: db);
              final encryptedBytes = await backupService.createEncryptedBackup(passphrase: masterPass);
              final fileName = 'spreadlog_backup_${DateTime.now().toUtc().millisecondsSinceEpoch}.spbackup';

              final transport = GoogleDriveBackupTransport(authService);
              await transport.dispatchBackup(
                encryptedBytes: encryptedBytes,
                suggestedFileName: fileName,
              );

              await settingsRepo.recordBackupResult(
                timestamp: DateTime.now().toUtc(),
                status: 'Google Drive Auto-Sync OK',
              );
              return true;
            } finally {
              await db.close();
            }
          }
        }
      }

      // Check if automated SMTP email backup is enabled
      if (settings.autoBackupEnabled && settings.smtpHost != null && settings.smtpHost!.isNotEmpty) {
        final masterPass = await settingsRepo.getMasterPassphrase();
        final smtpPass = await settingsRepo.getSmtpPassword();
        if (masterPass != null && masterPass.isNotEmpty && smtpPass != null) {
          final db = AppDatabase();
          try {
            final backupService = BackupService(db: db);
            final encryptedBytes = await backupService.createEncryptedBackup(passphrase: masterPass);
            final fileName = 'spreadlog_backup_${DateTime.now().toUtc().millisecondsSinceEpoch}.spbackup';

            final config = SmtpConfig(
              host: settings.smtpHost!,
              port: settings.smtpPort,
              username: settings.smtpUsername ?? '',
              password: smtpPass,
              useTls: settings.smtpUseTls,
              senderEmail: settings.primaryEmail ?? settings.smtpUsername ?? '',
            );

            final transport = SmtpBackupTransport(config);
            await transport.dispatchBackup(
              encryptedBytes: encryptedBytes,
              suggestedFileName: fileName,
              recipientEmail: settings.primaryEmail,
            );

            await settingsRepo.recordBackupResult(
              timestamp: DateTime.now().toUtc(),
              status: 'SMTP Auto-Backup OK',
            );
            return true;
          } finally {
            await db.close();
          }
        }
      }
    } catch (e) {
      debugPrint('Background backup task error: $e');
    }
    return Future.value(true);
  });
}

/// Service managing Workmanager background execution for automated backups.
class BackupWorkmanagerService {
  static Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    try {
      await Workmanager().initialize(
        backupCallbackDispatcher,
      );
    } catch (e) {
      debugPrint('Workmanager initialization skipped: $e');
    }
  }

  static Future<void> schedulePeriodicBackup({
    required int intervalDays,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    try {
      final duration = Duration(days: intervalDays.clamp(1, 30));
      await Workmanager().registerPeriodicTask(
        periodicBackupTaskKey,
        periodicBackupTaskKey,
        frequency: duration,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
    } catch (e) {
      debugPrint('Failed to schedule periodic backup: $e');
    }
  }

  static Future<void> cancelPeriodicBackup() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    try {
      await Workmanager().cancelByUniqueName(periodicBackupTaskKey);
    } catch (e) {
      debugPrint('Failed to cancel periodic backup: $e');
    }
  }
}
