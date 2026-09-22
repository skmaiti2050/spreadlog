import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

/// Unique task identifier for periodic automated backups.
const String periodicBackupTaskKey = 'com.example.aviation_logbook.periodic_backup';

/// Callback dispatcher invoked by Android/iOS background Workmanager.
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Background task execution hook
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
