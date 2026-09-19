import 'ledger_totals.dart';

/// Aggregated totals for a specific aircraft type/model (e.g. C172, PA28, BE76, FNPT II).
///
/// Pure Dart value object. Durations stored as integer minutes.
class AircraftTypeSummary {
  final String aircraftType;
  final LedgerTotals totals;
  final DateTime? dateLastFlown;

  const AircraftTypeSummary({
    required this.aircraftType,
    required this.totals,
    this.dateLastFlown,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AircraftTypeSummary &&
          runtimeType == other.runtimeType &&
          aircraftType == other.aircraftType &&
          totals == other.totals &&
          dateLastFlown == other.dateLastFlown;

  @override
  int get hashCode => Object.hash(aircraftType, totals, dateLastFlown);

  @override
  String toString() =>
      'AircraftTypeSummary(type: $aircraftType, total: ${totals.totalFlightTimeMinutes}m, lastFlown: $dateLastFlown)';
}

