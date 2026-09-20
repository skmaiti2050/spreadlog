import 'endorsement_category.dart';

/// Immutable domain model representing a scanned legal endorsement, rating certificate,
/// or signed logbook document.
///
/// In accordance with statutory audit standards, once an endorsement document is created,
/// its original image and SHA-256 fingerprint are immutable. Revisions are tracked
/// through superseding relationships ([supersededBy] / [supersedes]).
class EndorsementDocument {
  final String id;
  final EndorsementCategory category;
  final DateTime endorsementDate;
  final int? pageNumber;
  final String originalPath;
  final String? processedPath;
  final String? thumbnailPath;
  final String sha256;
  final DateTime capturedAt;
  final String? supersededBy;
  final String? supersedes;
  final String? notes;

  const EndorsementDocument({
    required this.id,
    required this.category,
    required this.endorsementDate,
    this.pageNumber,
    required this.originalPath,
    this.processedPath,
    this.thumbnailPath,
    required this.sha256,
    required this.capturedAt,
    this.supersededBy,
    this.supersedes,
    this.notes,
  });

  /// True if this document has been superseded by a newer replacement scan.
  bool get isSuperseded => supersededBy != null && supersededBy!.isNotEmpty;

  /// True if this document was created as a replacement for a prior document.
  bool get isReplacement => supersedes != null && supersedes!.isNotEmpty;

  EndorsementDocument copyWith({
    String? id,
    EndorsementCategory? category,
    DateTime? endorsementDate,
    int? pageNumber,
    String? originalPath,
    String? processedPath,
    String? thumbnailPath,
    String? sha256,
    DateTime? capturedAt,
    String? supersededBy,
    String? supersedes,
    String? notes,
  }) {
    return EndorsementDocument(
      id: id ?? this.id,
      category: category ?? this.category,
      endorsementDate: endorsementDate ?? this.endorsementDate,
      pageNumber: pageNumber ?? this.pageNumber,
      originalPath: originalPath ?? this.originalPath,
      processedPath: processedPath ?? this.processedPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      sha256: sha256 ?? this.sha256,
      capturedAt: capturedAt ?? this.capturedAt,
      supersededBy: supersededBy ?? this.supersededBy,
      supersedes: supersedes ?? this.supersedes,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.code,
      'endorsementDate': endorsementDate.toIso8601String(),
      'pageNumber': pageNumber,
      'originalPath': originalPath,
      'processedPath': processedPath,
      'thumbnailPath': thumbnailPath,
      'sha256': sha256,
      'capturedAt': capturedAt.toIso8601String(),
      'supersededBy': supersededBy,
      'supersedes': supersedes,
      'notes': notes,
    };
  }

  factory EndorsementDocument.fromJson(Map<String, dynamic> json) {
    return EndorsementDocument(
      id: json['id'] as String,
      category: EndorsementCategory.fromCode(json['category'] as String),
      endorsementDate: DateTime.parse(json['endorsementDate'] as String),
      pageNumber: json['pageNumber'] as int?,
      originalPath: json['originalPath'] as String,
      processedPath: json['processedPath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      sha256: json['sha256'] as String,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      supersededBy: json['supersededBy'] as String?,
      supersedes: json['supersedes'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EndorsementDocument &&
        other.id == id &&
        other.category == category &&
        other.endorsementDate == endorsementDate &&
        other.pageNumber == pageNumber &&
        other.originalPath == originalPath &&
        other.processedPath == processedPath &&
        other.thumbnailPath == thumbnailPath &&
        other.sha256 == sha256 &&
        other.capturedAt == capturedAt &&
        other.supersededBy == supersededBy &&
        other.supersedes == supersedes &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      category,
      endorsementDate,
      pageNumber,
      originalPath,
      processedPath,
      thumbnailPath,
      sha256,
      capturedAt,
      supersededBy,
      supersedes,
      notes,
    );
  }
}

