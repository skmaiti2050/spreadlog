/// SACAA rule for electronic logbooks: entries must be printed on paper at
/// least every 90 days and filed in sequence (Civil Aviation Regulations
/// 61.01.8).
///
/// 100% pure Dart.
class PrintReminder {
  const PrintReminder._();

  static const Duration interval = Duration(days: 90);

  /// Whether entries are overdue for printing.
  ///
  /// [entryCreatedAt] are the times flights were logged. Entries logged
  /// after [lastPrintedAt] (all of them if never printed) are unprinted; a
  /// print is due once the oldest unprinted entry has waited [interval]
  /// since the last print, or since it was logged if nothing was printed.
  static bool isDue({
    required DateTime now,
    required DateTime? lastPrintedAt,
    required Iterable<DateTime> entryCreatedAt,
  }) {
    final unprinted = entryCreatedAt.where(
      (t) => lastPrintedAt == null || t.isAfter(lastPrintedAt),
    );
    if (unprinted.isEmpty) return false;

    final since =
        lastPrintedAt ?? unprinted.reduce((a, b) => a.isBefore(b) ? a : b);
    return now.difference(since) >= interval;
  }
}
