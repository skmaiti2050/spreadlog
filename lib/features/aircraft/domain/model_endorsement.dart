class ModelEndorsement {
  final String id;
  final String aircraftModelId;
  final DateTime pilotDate;
  final DateTime? instructorDate;
  final String? instructorName;
  final String? instructorLicence;
  final String? sourceDocumentId;
  final String? notes;
  final DateTime createdAt;

  const ModelEndorsement({
    required this.id,
    required this.aircraftModelId,
    required this.pilotDate,
    this.instructorDate,
    this.instructorName,
    this.instructorLicence,
    this.sourceDocumentId,
    this.notes,
    required this.createdAt,
  });

  ModelEndorsement copyWith({
    String? id,
    String? aircraftModelId,
    DateTime? pilotDate,
    DateTime? instructorDate,
    String? instructorName,
    String? instructorLicence,
    String? sourceDocumentId,
    String? notes,
    DateTime? createdAt,
  }) {
    return ModelEndorsement(
      id: id ?? this.id,
      aircraftModelId: aircraftModelId ?? this.aircraftModelId,
      pilotDate: pilotDate ?? this.pilotDate,
      instructorDate: instructorDate ?? this.instructorDate,
      instructorName: instructorName ?? this.instructorName,
      instructorLicence: instructorLicence ?? this.instructorLicence,
      sourceDocumentId: sourceDocumentId ?? this.sourceDocumentId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'aircraftModelId': aircraftModelId,
      'pilotDate': pilotDate.toIso8601String(),
      'instructorDate': instructorDate?.toIso8601String(),
      'instructorName': instructorName,
      'instructorLicence': instructorLicence,
      'sourceDocumentId': sourceDocumentId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ModelEndorsement.fromJson(Map<String, dynamic> json) {
    return ModelEndorsement(
      id: json['id'] as String,
      aircraftModelId: json['aircraftModelId'] as String,
      pilotDate: DateTime.parse(json['pilotDate'] as String),
      instructorDate: json['instructorDate'] != null
          ? DateTime.parse(json['instructorDate'] as String)
          : null,
      instructorName: json['instructorName'] as String?,
      instructorLicence: json['instructorLicence'] as String?,
      sourceDocumentId: json['sourceDocumentId'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelEndorsement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ModelEndorsement(id: $id, model: $aircraftModelId, pilotDate: $pilotDate)';
}

