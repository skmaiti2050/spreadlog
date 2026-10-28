import 'package:aviation_logbook/features/backups/domain/auto_backup_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('driveAutoBackupStatus', () {
    final run = DateTime(2026, 10, 28, 9, 5);

    test('is hidden while automatic backups are off', () {
      expect(
        driveAutoBackupStatus(enabled: false, lastRun: run, error: null),
        isNull,
      );
    });

    test('says it is waiting before the first run', () {
      final status = driveAutoBackupStatus(
        enabled: true,
        lastRun: null,
        error: null,
      );
      expect(status?.succeeded, isNull);
      expect(status?.message, 'Waiting for the first automatic backup.');
    });

    test('shows when the last run succeeded', () {
      final status = driveAutoBackupStatus(
        enabled: true,
        lastRun: run,
        error: null,
      );
      expect(status?.succeeded, isTrue);
      expect(status?.message, 'Last automatic backup: 28 Oct 2026, 09:05');
    });

    test('shows why the last run failed', () {
      final status = driveAutoBackupStatus(
        enabled: true,
        lastRun: run,
        error: 'Not signed in to Google.',
      );
      expect(status?.succeeded, isFalse);
      expect(
        status?.message,
        'Last automatic backup failed (28 Oct 2026, 09:05): '
        'Not signed in to Google.',
      );
    });
  });
}
