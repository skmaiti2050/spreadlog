enum InstructorCategory {
  singleEngine,
  multiEngine,
  fstd,
}

/// Flight instructor flight time experience.
class InstructionTime {
  final String? id;
  final String? flightId;
  final InstructorCategory category;
  final int durationMinutes;

  const InstructionTime({
    this.id,
    this.flightId,
    required this.category,
    required this.durationMinutes,
  }) : assert(durationMinutes >= 0, 'Duration minutes cannot be negative');

  InstructionTime copyWith({
    String? id,
    String? flightId,
    InstructorCategory? category,
    int? durationMinutes,
  }) {
    return InstructionTime(
      id: id ?? this.id,
      flightId: flightId ?? this.flightId,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstructionTime &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          durationMinutes == other.durationMinutes;

  @override
  int get hashCode => Object.hash(category, durationMinutes);

  @override
  String toString() => 'InstructionTime($category: ${durationMinutes}m)';
}

