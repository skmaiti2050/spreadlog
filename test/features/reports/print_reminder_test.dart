import 'package:aviation_logbook/features/reports/domain/print_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 26);
  DateTime daysAgo(int days) => now.subtract(Duration(days: days));

  test('nothing to print without entries', () {
    expect(
      PrintReminder.isDue(now: now, lastPrintedAt: null, entryCreatedAt: []),
      isFalse,
    );
  });

  test('never printed: due once the oldest entry is 90 days old', () {
    expect(
      PrintReminder.isDue(
        now: now,
        lastPrintedAt: null,
        entryCreatedAt: [daysAgo(89), daysAgo(10)],
      ),
      isFalse,
    );
    expect(
      PrintReminder.isDue(
        now: now,
        lastPrintedAt: null,
        entryCreatedAt: [daysAgo(90), daysAgo(10)],
      ),
      isTrue,
    );
  });

  test('printed recently: not due even with new entries', () {
    expect(
      PrintReminder.isDue(
        now: now,
        lastPrintedAt: daysAgo(30),
        entryCreatedAt: [daysAgo(200), daysAgo(5)],
      ),
      isFalse,
    );
  });

  test('printed 90 days ago: due only if entries were logged since', () {
    expect(
      PrintReminder.isDue(
        now: now,
        lastPrintedAt: daysAgo(120),
        entryCreatedAt: [daysAgo(130)],
      ),
      isFalse,
    );
    expect(
      PrintReminder.isDue(
        now: now,
        lastPrintedAt: daysAgo(120),
        entryCreatedAt: [daysAgo(130), daysAgo(60)],
      ),
      isTrue,
    );
  });
}
