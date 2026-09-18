/// Take-offs and Landings count breakdown.
class Landings {
  final int dayCount;
  final int nightCount;

  const Landings({
    this.dayCount = 0,
    this.nightCount = 0,
  })  : assert(dayCount >= 0, 'Day landing count cannot be negative'),
        assert(nightCount >= 0, 'Night landing count cannot be negative');

  int get totalCount => dayCount + nightCount;

  Landings copyWith({
    int? dayCount,
    int? nightCount,
  }) {
    return Landings(
      dayCount: dayCount ?? this.dayCount,
      nightCount: nightCount ?? this.nightCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Landings &&
          runtimeType == other.runtimeType &&
          dayCount == other.dayCount &&
          nightCount == other.nightCount;

  @override
  int get hashCode => Object.hash(dayCount, nightCount);

  @override
  String toString() => 'Landings(day: $dayCount, night: $nightCount)';
}

