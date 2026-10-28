/// File name for a backup archive made at [now] (local time), e.g.
/// `spreadlog_backup_2026-10-28_1430.spbackup`. Manual and automatic backups
/// use the same name so they sort and read alike; the time tells same-day
/// backups apart, since Drive allows duplicate names.
String backupFileName(DateTime now) {
  final date = now.toIso8601String().substring(0, 10);
  final time =
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}';
  return 'spreadlog_backup_${date}_$time.spbackup';
}
