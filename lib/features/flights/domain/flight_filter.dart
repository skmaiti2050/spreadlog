import '../../aircraft/domain/aircraft_model.dart';
import 'flight.dart';
import 'flight_time.dart';

enum FlightSort { newest, oldest, registration, aircraftType, duration }

/// Shared selection rules for flight lists and summaries. Dates are inclusive
/// calendar dates; sorting never changes the source list or physical ledger.
class FlightFilter {
  final String query;
  final Set<String> registrations;
  final Set<String> modelIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final AircraftCategory? category;
  final AircraftClass? aircraftClass;
  final PilotRole? role;
  final TimePeriod? period;
  final FlightSort sort;
  final bool descending;

  const FlightFilter({
    this.query = '',
    this.registrations = const {},
    this.modelIds = const {},
    this.startDate,
    this.endDate,
    this.category,
    this.aircraftClass,
    this.role,
    this.period,
    this.sort = FlightSort.newest,
    this.descending = false,
  });

  static DateTime day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime yearBefore(DateTime value) {
    final lastDay = DateTime(value.year - 1, value.month + 1, 0).day;
    return DateTime(
      value.year - 1,
      value.month,
      value.day > lastDay ? lastDay : value.day,
    );
  }

  String get description => [
    periodLabel,
    if (query.trim().isNotEmpty) 'Search: ${query.trim()}',
    if (registrations.isNotEmpty) 'Registrations: ${registrations.join(', ')}',
    if (modelIds.isNotEmpty) 'Types: ${modelIds.join(', ')}',
    if (category != null) 'Category: ${category!.name}',
    if (aircraftClass != null) 'Class: ${aircraftClass!.name}',
    if (role != null) 'Role: ${role!.name}',
    if (period != null) 'Period: ${period!.name}',
  ].join(' | ');

  bool get isFiltered =>
      query.trim().isNotEmpty ||
      registrations.isNotEmpty ||
      modelIds.isNotEmpty ||
      startDate != null ||
      endDate != null ||
      category != null ||
      aircraftClass != null ||
      role != null ||
      period != null;

  String get periodLabel {
    String format(DateTime date) =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    if (startDate == null && endDate == null) return 'All time';
    return '${startDate == null ? 'Beginning' : format(startDate!)} to '
        '${endDate == null ? 'present' : format(endDate!)}';
  }

  List<Flight> apply(
    Iterable<Flight> flights, {
    Map<String, AircraftModel> models = const {},
  }) {
    final text = query.trim().toLowerCase();
    final selected = flights.where((flight) {
      final model = models[flight.aircraftModelId];
      final date = day(flight.date);
      if (startDate != null && date.isBefore(day(startDate!))) return false;
      if (endDate != null && date.isAfter(day(endDate!))) return false;
      if (registrations.isNotEmpty &&
          !registrations.contains(flight.registration)) {
        return false;
      }
      if (modelIds.isNotEmpty && !modelIds.contains(flight.aircraftModelId)) {
        return false;
      }
      final actualCategory = flight.isFstd
          ? AircraftCategory.fstd
          : model?.category ?? flight.aircraftCategory;
      if (category != null && actualCategory != category) return false;
      if ((aircraftClass != null || role != null || period != null) &&
          !flight.flightTimes.any(
            (time) =>
                (aircraftClass == null ||
                    time.aircraftClass == aircraftClass) &&
                (role == null || time.role == role) &&
                (period == null || time.period == period),
          )) {
        return false;
      }
      return text.isEmpty ||
          [
            flight.registration,
            flight.aircraftModelId ?? '',
            model?.displayName ?? '',
            flight.remarks,
            flight.picName,
          ].any((value) => value.toLowerCase().contains(text));
    }).toList();
    selected.sort((a, b) {
      final result = switch (sort) {
        FlightSort.newest => b.date.compareTo(a.date),
        FlightSort.oldest => a.date.compareTo(b.date),
        FlightSort.registration => a.registration.compareTo(b.registration),
        FlightSort.aircraftType => (a.aircraftModelId ?? '').compareTo(
          b.aircraftModelId ?? '',
        ),
        FlightSort.duration => a.totalDurationMinutes.compareTo(
          b.totalDurationMinutes,
        ),
      };
      final stable = result == 0 ? a.id.compareTo(b.id) : result;
      return descending ? -stable : stable;
    });
    return selected;
  }

  FlightFilter withQuery(String value) => FlightFilter(
    query: value,
    registrations: registrations,
    modelIds: modelIds,
    startDate: startDate,
    endDate: endDate,
    category: category,
    aircraftClass: aircraftClass,
    role: role,
    period: period,
    sort: sort,
    descending: descending,
  );
}
