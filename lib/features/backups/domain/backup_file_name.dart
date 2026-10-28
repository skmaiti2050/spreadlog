/// File name for a backup archive made at [now] (local date), e.g.
/// `spreadlog_backup_2026-10-28.spbackup`. Manual and automatic backups use
/// the same name so they sort and read alike.
String backupFileName(DateTime now) {
  final date = now.toIso8601String().substring(0, 10);
  return 'spreadlog_backup_$date.spbackup';
}
