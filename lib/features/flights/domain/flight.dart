import 'flight_time.dart';
import 'instruction_time.dart';
import 'instrument_time.dart';
import 'landings.dart';

/// Flight aggregate root entity.
class Flight {
  final String id;
  final DateTime date;
  final String? aircraftModelId;
  final String registration;
  final String picName;
  final String remarks;
  final bool soloCrossCountry;
  final int fstdActualMinutes;
  final List<FlightTime> flightTimes;
  final InstrumentTime? instrumentTime;
  final List<InstructionTime> instructionTimes;
  final Landings landings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Flight({
    required this.id,
    required this.date,
    this.aircraftModelId,
    required this.registration,
    required this.picName,
    this.remarks = '',
    this.soloCrossCountry = false,
    this.fstdActualMinutes = 0,
    this.flightTimes = const [],
    this.instrumentTime,
    this.instructionTimes = const [],
    this.landings = const Landings(),
    required this.createdAt,
    required this.updatedAt,
  }) : assert(fstdActualMinutes >= 0, 'FSTD actual minutes cannot be negative');

  /// Total operational flight duration for this flight in integer minutes.
  /// Matches SACAA Appendix A total flight time: FSTD actual (Col 13) + Col 14..29.
  int get totalDurationMinutes {
    final flightTimeSum = flightTimes.fold<int>(0, (sum, ft) => sum + ft.durationMinutes);
    return fstdActualMinutes + flightTimeSum;
  }

  Flight copyWith({
    String? id,
    DateTime? date,
    String? aircraftModelId,
    String? registration,
    String? picName,
    String? remarks,
    bool? soloCrossCountry,
    int? fstdActualMinutes,
    List<FlightTime>? flightTimes,
    InstrumentTime? instrumentTime,
    List<InstructionTime>? instructionTimes,
    Landings? landings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flight(
      id: id ?? this.id,
      date: date ?? this.date,
      aircraftModelId: aircraftModelId ?? this.aircraftModelId,
      registration: registration ?? this.registration,
      picName: picName ?? this.picName,
      remarks: remarks ?? this.remarks,
      soloCrossCountry: soloCrossCountry ?? this.soloCrossCountry,
      fstdActualMinutes: fstdActualMinutes ?? this.fstdActualMinutes,
      flightTimes: flightTimes ?? this.flightTimes,
      instrumentTime: instrumentTime ?? this.instrumentTime,
      instructionTimes: instructionTimes ?? this.instructionTimes,
      landings: landings ?? this.landings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Flight && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Flight(id: $id, date: $date, reg: $registration, total: ${totalDurationMinutes}m)';
}

