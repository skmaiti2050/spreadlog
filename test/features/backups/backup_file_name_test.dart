import 'package:aviation_logbook/features/backups/domain/backup_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backup file names carry the local date and time', () {
    expect(
      backupFileName(DateTime(2026, 10, 28, 9, 5)),
      'spreadlog_backup_2026-10-28_0905.spbackup',
    );
  });
}
