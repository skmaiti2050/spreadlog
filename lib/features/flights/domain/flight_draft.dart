/// Unfinished input is deliberately separate from a logged [Flight].
/// Raw strings survive even when they cannot yet be parsed as numbers.
class FlightDraft {
  static const newEntryKey = 'new';
  static String keyFor(String? flightId) =>
      flightId == null ? newEntryKey : 'edit:$flightId';

  final String? flightId;
  final String? baseRevision;
  final DateTime updatedAt;
  final Map<String, String> fields;
  final Map<String, int> validatedValues;

  FlightDraft({
    this.flightId,
    this.baseRevision,
    required this.updatedAt,
    required Map<String, String> fields,
    Map<String, int> validatedValues = const {},
  }) : fields = Map.unmodifiable(fields),
       validatedValues = Map.unmodifiable(validatedValues);

  String get key => keyFor(flightId);

  Map<String, Object?> toJson() => {
    'version': 1,
    'flightId': flightId,
    'baseRevision': baseRevision,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'fields': fields,
    'validatedValues': validatedValues,
  };

  factory FlightDraft.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported flight draft version');
    }
    return FlightDraft(
      flightId: json['flightId'] as String?,
      baseRevision: json['baseRevision'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      fields: Map<String, String>.from(json['fields'] as Map),
      validatedValues: Map<String, int>.from(json['validatedValues'] as Map),
    );
  }
}

abstract interface class FlightDraftRepository {
  Future<FlightDraft?> get(String? flightId);
  Future<void> save(FlightDraft draft);
  Future<void> discard(String? flightId);
}

class FlightDraftConflict implements Exception {
  const FlightDraftConflict();

  @override
  String toString() =>
      'The original flight changed or was deleted. '
      'Your draft is kept. Reopen the entry to review the latest flight.';
}
