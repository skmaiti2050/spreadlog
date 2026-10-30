import 'package:aviation_logbook/features/backups/domain/auto_backup_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('autoBackupStatus', () {
    final run = DateTime(2026, 10, 28, 9, 5);

    test('is hidden while automatic backups are off', () {
      expect(
        autoBackupStatus(enabled: false, lastRun: run, error: null),
        isNull,
      );
    });

    test('says it is waiting before the first run', () {
      final status = autoBackupStatus(
        enabled: true,
        lastRun: null,
        error: null,
      );
      expect(status?.succeeded, isNull);
      expect(status?.message, 'Waiting for the first automatic backup.');
    });

    test('shows when the last run succeeded', () {
      final status = autoBackupStatus(enabled: true, lastRun: run, error: null);
      expect(status?.succeeded, isTrue);
      expect(status?.message, 'Last automatic backup: 28 Oct 2026, 09:05');
    });

    test('shows why the last run failed', () {
      final status = autoBackupStatus(
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

  group('skipAutoBackup', () {
    final last = DateTime.utc(2026, 10, 28, 9);

    test('skips within 24 hours of a successful run', () {
      expect(
        skipAutoBackup(
          lastRun: last,
          lastError: null,
          now: last.add(const Duration(hours: 23, minutes: 59)),
        ),
        isTrue,
      );
    });

    test('runs once 24 hours have passed', () {
      expect(
        skipAutoBackup(
          lastRun: last,
          lastError: null,
          now: last.add(const Duration(hours: 24)),
        ),
        isFalse,
      );
    });

    test('retries straight away after a failed run', () {
      expect(
        skipAutoBackup(
          lastRun: last,
          lastError: 'Not signed in to Google.',
          now: last.add(const Duration(minutes: 5)),
        ),
        isFalse,
      );
    });

    test('runs when there has been no run yet', () {
      expect(
        skipAutoBackup(lastRun: null, lastError: null, now: last),
        isFalse,
      );
    });
  });
}
