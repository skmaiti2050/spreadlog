import '../../aircraft/domain/aircraft_model.dart';

enum TimePeriod {
  day,
  night,
}

enum PilotRole {
  dual,
  pic,
  picus,
  copilot,
}

/// Represents flight duration in integer minutes for a specific class, period, and role.
class FlightTime {
  final String? id;
  final String? flightId;
  final AircraftClass aircraftClass;
  final TimePeriod period;
  final PilotRole role;
  final int durationMinutes;

  const FlightTime({
    this.id,
    this.flightId,
    required this.aircraftClass,
    required this.period,
    required this.role,
    required this.durationMinutes,
  }) : assert(durationMinutes >= 0, 'Duration minutes cannot be negative');

  FlightTime copyWith({
    String? id,
    String? flightId,
    AircraftClass? aircraftClass,
    TimePeriod? period,
    PilotRole? role,
    int? durationMinutes,
  }) {
    return FlightTime(
      id: id ?? this.id,
      flightId: flightId ?? this.flightId,
      aircraftClass: aircraftClass ?? this.aircraftClass,
      period: period ?? this.period,
      role: role ?? this.role,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlightTime &&
          runtimeType == other.runtimeType &&
          aircraftClass == other.aircraftClass &&
          period == other.period &&
          role == other.role &&
          durationMinutes == other.durationMinutes;

  @override
  int get hashCode => Object.hash(aircraftClass, period, role, durationMinutes);

  @override
  String toString() =>
      'FlightTime($aircraftClass, $period, $role: ${durationMinutes}m)';
}

