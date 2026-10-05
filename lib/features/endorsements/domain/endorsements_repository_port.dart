import 'endorsement_page.dart';
import 'endorsement_category.dart';
import 'endorsement_document.dart';

/// Pure Dart domain port defining operations for endorsement document storage and verification.
abstract interface class EndorsementsRepositoryPort {
  /// Watches all stored endorsement documents.
  Stream<List<EndorsementDocument>> watchEndorsements({
    bool includeSuperseded = false,
  });

  /// Fetches all stored endorsement documents.
  Future<List<EndorsementDocument>> getEndorsements({
    bool includeSuperseded = false,
  });

  /// Fetches an endorsement document by its unique identifier.
  Future<EndorsementDocument?> getEndorsementById(String id);

  /// Saves a newly scanned/imported endorsement document.
  /// Computes its cryptographic SHA-256 fingerprint, persists the file, and stores metadata.
  /// If [supersedesId] is provided, marks the existing document as superseded in an atomic transaction.
  Future<EndorsementDocument> saveEndorsement({
    required EndorsementCategory category,
    required DateTime endorsementDate,
    int? pageNumber,
    required List<int> imageBytes,
    required String fileExtension,
    String? notes,
    String? supersedesId,
  });

  /// Saves one complete ordered document, publishing metadata only after all files exist.
  Future<EndorsementDocument> saveDocument({
    required EndorsementCategory category,
    required DateTime endorsementDate,
    required List<DocumentPageInput> pages,
    int? pageNumber,
    String? notes,
    String? supersedesId,
  });

  /// Verifies whether the on-disk file bytes still match the registered SHA-256 hash.
  Future<bool> verifyIntegrity(String id);

  /// Deletes an endorsement document record.
  Future<void> deleteEndorsement(String id);
}
