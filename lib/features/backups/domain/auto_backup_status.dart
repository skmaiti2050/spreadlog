import '../../../core/utils/time_utils.dart';

/// Minimum gap between automatic backups of one kind. Re-enabling the switch, or the
/// app re-scheduling at startup, starts a run right away; without this it
/// would add another backup each time.
const autoBackupMinGap = Duration(hours: 24);

/// Whether a background run should be skipped because the last one
/// succeeded less than [autoBackupMinGap] before [now].
bool skipAutoBackup({
  required DateTime? lastRun,
  required String? lastError,
  required DateTime now,
}) =>
    lastRun != null &&
    lastError == null &&
    now.difference(lastRun) < autoBackupMinGap;

/// Status line for an automatic background backup (Drive or email), or null
/// when it is switched off. [succeeded] is null until the first run.
({String message, bool? succeeded})? autoBackupStatus({
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
