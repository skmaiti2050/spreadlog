/// One immutable original image in an ordered document.
class EndorsementPage {
  final String originalPath;
  final String sha256;

  /// The source logbook page number, distinct from its position in the scan.
  final int? pageNumber;

  const EndorsementPage({
    required this.originalPath,
    required this.sha256,
    this.pageNumber,
  });

  Map<String, dynamic> toJson() => {
    'originalPath': originalPath,
    'sha256': sha256,
    'pageNumber': pageNumber,
  };

  factory EndorsementPage.fromJson(Map<String, dynamic> json) =>
      EndorsementPage(
        originalPath: json['originalPath'] as String,
        sha256: json['sha256'] as String,
        pageNumber: json['pageNumber'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      other is EndorsementPage &&
      originalPath == other.originalPath &&
      sha256 == other.sha256 &&
      pageNumber == other.pageNumber;
  @override
  int get hashCode => Object.hash(originalPath, sha256, pageNumber);
}

/// Input bytes for one page of a new scan/import session.
class DocumentPageInput {
  final List<int> imageBytes;
  final String fileExtension;
  DocumentPageInput({
    required List<int> imageBytes,
    required this.fileExtension,
  }) : imageBytes = List.unmodifiable(imageBytes);
}
