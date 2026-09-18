/// Instrument flight time representation with navigational aid particulars.
class InstrumentTime {
  final String? id;
  final String? flightId;
  final String? navaids;
  final String? place;
  final int actualMinutes;
  final int fstdMinutes;

  const InstrumentTime({
    this.id,
    this.flightId,
    this.navaids,
    this.place,
    this.actualMinutes = 0,
    this.fstdMinutes = 0,
  })  : assert(actualMinutes >= 0, 'Actual instrument minutes cannot be negative'),
        assert(fstdMinutes >= 0, 'FSTD instrument minutes cannot be negative');

  int get totalMinutes => actualMinutes + fstdMinutes;
  bool get isEmpty => actualMinutes == 0 && fstdMinutes == 0 && navaids == null && place == null;

  InstrumentTime copyWith({
    String? id,
    String? flightId,
    String? navaids,
    String? place,
    int? actualMinutes,
    int? fstdMinutes,
  }) {
    return InstrumentTime(
      id: id ?? this.id,
      flightId: flightId ?? this.flightId,
      navaids: navaids ?? this.navaids,
      place: place ?? this.place,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      fstdMinutes: fstdMinutes ?? this.fstdMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstrumentTime &&
          runtimeType == other.runtimeType &&
          navaids == other.navaids &&
          place == other.place &&
          actualMinutes == other.actualMinutes &&
          fstdMinutes == other.fstdMinutes;

  @override
  int get hashCode => Object.hash(navaids, place, actualMinutes, fstdMinutes);

  @override
  String toString() =>
      'InstrumentTime(actual: ${actualMinutes}m, fstd: ${fstdMinutes}m, navaids: $navaids, place: $place)';
}

