import 'flight.dart';

/// Meter readings use integer tenths; logged flight time stays in minutes.
class HobbsReading {
  final int startTenths;
  final int endTenths;

  HobbsReading({required this.startTenths, required this.endTenths}) {
    if (startTenths < 0 || endTenths <= startTenths) {
      throw ArgumentError('End reading must exceed the nonnegative start.');
    }
  }

  int get elapsedMinutes => (endTenths - startTenths) * 6;

  static String normalizeRegistration(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static int? previousEnd(
    Iterable<Flight> flights, {
    required String registration,
    required DateTime date,
    String? excludingId,
    DateTime? beforeCreatedAt,
  }) {
    Flight? previous;
    final key = normalizeRegistration(registration);
    if (key.isEmpty) return null;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day + 1);
    for (final flight in flights) {
      if (flight.id == excludingId ||
          flight.hobbsEndTenths == null ||
          !flight.date.isBefore(endOfDay) ||
          (beforeCreatedAt != null &&
              !flight.date.isBefore(startOfDay) &&
              flight.createdAt.isAfter(beforeCreatedAt)) ||
          normalizeRegistration(flight.registration) != key) {
        continue;
      }
      if (previous == null ||
          flight.date.isAfter(previous.date) ||
          (flight.date == previous.date &&
              flight.createdAt.isAfter(previous.createdAt))) {
        previous = flight;
      }
    }
    return previous?.hobbsEndTenths;
  }
}
