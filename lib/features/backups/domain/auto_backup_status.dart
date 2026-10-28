import '../../../core/utils/time_utils.dart';

/// Status line for the background Google Drive backup, or null when it is
/// switched off. [succeeded] is null until the first run.
({String message, bool? succeeded})? driveAutoBackupStatus({
  required bool enabled,
  required DateTime? lastRun,
  required String? error,
}) {
  if (!enabled) return null;
  if (lastRun == null) {
    return (
      message: 'Waiting for the first automatic backup.',
      succeeded: null,
    );
  }
  final local = lastRun.toLocal();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  final when = '${TimeUtils.formatDate(local)}, $time';
  return error == null
      ? (message: 'Last automatic backup: $when', succeeded: true)
      : (
          message: 'Last automatic backup failed ($when): $error',
          succeeded: false,
        );
}
