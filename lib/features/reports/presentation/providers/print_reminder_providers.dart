import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../flights/presentation/providers/flights_providers.dart';
import '../../domain/print_reminder.dart';

/// When the logbook PDF was last printed or shared, persisted locally.
class LastPrintedNotifier extends Notifier<DateTime?> {
  static const _prefKey = 'spreadlog_logbook_last_printed_at';

  @override
  DateTime? build() {
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefKey);
      if (stored != null) state = DateTime.tryParse(stored);
    } catch (_) {}
  }

  Future<void> markPrinted([DateTime? at]) async {
    final printedAt = at ?? DateTime.now();
    state = printedAt;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, printedAt.toIso8601String());
    } catch (_) {}
  }
}

final lastPrintedProvider = NotifierProvider<LastPrintedNotifier, DateTime?>(
  LastPrintedNotifier.new,
);

/// True when SACAA's 90-day paper printout of the logbook is overdue.
final printReminderDueProvider = Provider<bool>((ref) {
  final flights = ref.watch(flightsStreamProvider).value ?? const [];
  return PrintReminder.isDue(
    now: DateTime.now(),
    lastPrintedAt: ref.watch(lastPrintedProvider),
    entryCreatedAt: flights.map((f) => f.createdAt),
  );
});
