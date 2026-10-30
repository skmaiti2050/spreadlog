import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/database/app_database.dart';
import '../../../core/utils/email_address.dart';
import '../domain/auto_backup_status.dart';
import '../domain/backup_exceptions.dart';
import '../domain/backup_file_name.dart';
import 'backup_service.dart';
import 'backup_settings_repository.dart';
import 'google_auth_service.dart';
import 'transports/google_drive_backup_transport.dart';
import 'transports/smtp_backup_transport.dart';

/// Unique task identifier for periodic automated backups.
const String periodicBackupTaskKey = 'com.spreadlog.app.periodic_backup';

/// Callback dispatcher invoked by Android/iOS background Workmanager.
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Background engines don't register Dart-side plugin implementations
    // (google_sign_in_android, shared_preferences_android, ...) by themselves.
    DartPluginRegistrant.ensureInitialized();
    final settingsRepo = BackupSettingsRepository();
    try {
      final settings = await settingsRepo.loadSettings();
      // Independent: a Drive result must not stop the email backup.
      if (settings.autoSyncGoogleDrive) {
        await _runDriveBackup(settingsRepo, settings);
      }
      if (settings.autoBackupEnabled &&
          settings.smtpHost != null &&
          settings.smtpHost!.isNotEmpty) {
        await _runSmtpBackup(settingsRepo, settings);
      }
    } catch (e) {
      debugPrint('Background backup task error: $e');
    }
    return true;
  });
}

/// Uploads an encrypted backup to Google Drive and records the outcome,
/// which the Drive card shows. Skipped if one succeeded within the last day.
Future<void> _runDriveBackup(
  BackupSettingsRepository settingsRepo,
  BackupSettings settings,
) async {
  if (skipAutoBackup(
    lastRun: settings.lastDriveSyncDate,
    lastError: settings.lastDriveSyncError,
    now: DateTime.now().toUtc(),
  )) {
    return;
  }
  String? error;
  try {
    final authService = GoogleAuthService();
    final masterPass = await settingsRepo.getMasterPassphrase();
    if (await authService.signInSilently() == null) {
      error = 'Not signed in to Google. Sign in on the Drive tab.';
    } else if (masterPass == null || masterPass.isEmpty) {
      error = 'No master passphrase set.';
    } else {
      final db = AppDatabase();
      try {
        final encryptedBytes = await BackupService(db: db)
            .createEncryptedBackup(passphrase: masterPass);
        await GoogleDriveBackupTransport(authService).dispatchBackup(
          encryptedBytes: encryptedBytes,
          suggestedFileName: backupFileName(DateTime.now()),
        );
      } finally {
        await db.close();
      }
    }
  } on BackupTransportException catch (e) {
    error = e.message;
  } catch (e) {
    error = e.toString();
  }
  await settingsRepo.recordDriveSyncResult(
    timestamp: DateTime.now().toUtc(),
    error: error,
  );
}

/// Emails an encrypted backup through the configured SMTP server.
Future<void> _runSmtpBackup(
  BackupSettingsRepository settingsRepo,
  BackupSettings settings,
) async {
  final masterPass = await settingsRepo.getMasterPassphrase();
  final smtpPass = await settingsRepo.getSmtpPassword();
  if (masterPass == null ||
      masterPass.isEmpty ||
      smtpPass == null ||
      !isEmailAddress(settings.primaryEmail)) {
    return;
  }
  final db = AppDatabase();
  try {
    final encryptedBytes = await BackupService(db: db)
        .createEncryptedBackup(passphrase: masterPass);
    final config = SmtpConfig(
      host: settings.smtpHost!,
      port: settings.smtpPort,
      username: settings.smtpUsername ?? '',
      password: smtpPass,
      useTls: settings.smtpUseTls,
      senderEmail: settings.primaryEmail!,
    );
    await SmtpBackupTransport(config).dispatchBackup(
      encryptedBytes: encryptedBytes,
      suggestedFileName: backupFileName(DateTime.now()),
      recipientEmail: settings.primaryEmail,
    );
    await settingsRepo.recordBackupResult(
      timestamp: DateTime.now().toUtc(),
      status: 'SMTP Auto-Backup OK',
    );
  } finally {
    await db.close();
  }
}

/// Service managing Workmanager background execution for automated backups.
class BackupWorkmanagerService {
  /// Registers the background dispatcher and, when an automatic backup is
  /// switched on, (re)schedules the periodic task. Call once at app start:
  /// Workmanager rejects scheduling until it has been initialized.
  static Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    try {
      await Workmanager().initialize(backupCallbackDispatcher);
      final settings = await BackupSettingsRepository().loadSettings();
      if (settings.autoSyncGoogleDrive || settings.autoBackupEnabled) {
        await schedulePeriodicBackup(intervalDays: settings.backupIntervalDays);
      }
    } catch (e) {
      debugPrint('Workmanager initialization skipped: $e');
    }
  }

  /// Returns false if the task could not be scheduled.
  static Future<bool> schedulePeriodicBackup({
    required int intervalDays,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
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
      return true;
    } catch (e) {
      debugPrint('Failed to schedule periodic backup: $e');
      return false;
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
