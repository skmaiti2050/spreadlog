import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/endorsement_documents_table.dart';

part 'endorsements_dao.g.dart';

@DriftAccessor(tables: [
  EndorsementDocumentsTable,
])
class EndorsementsDao extends DatabaseAccessor<AppDatabase> with _$EndorsementsDaoMixin {
  EndorsementsDao(super.db);

  /// Selects all endorsements ordered by endorsementDate descending.
  Future<List<EndorsementDocumentsTableData>> getAllEndorsements({bool includeSuperseded = true}) {
    final query = select(endorsementDocumentsTable);
    if (!includeSuperseded) {
      query.where((t) => t.supersededBy.isNull());
    }
    return (query..orderBy([(t) => OrderingTerm.desc(t.endorsementDate)])).get();
  }

  /// Watches all endorsements ordered by endorsementDate descending.
  Stream<List<EndorsementDocumentsTableData>> watchAllEndorsements({bool includeSuperseded = true}) {
    final query = select(endorsementDocumentsTable);
    if (!includeSuperseded) {
      query.where((t) => t.supersededBy.isNull());
    }
    return (query..orderBy([(t) => OrderingTerm.desc(t.endorsementDate)])).watch();
  }

  /// Gets an endorsement document by its ID.
  Future<EndorsementDocumentsTableData?> getEndorsementById(String id) {
    return (select(endorsementDocumentsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Gets an endorsement document by its SHA-256 fingerprint.
  Future<EndorsementDocumentsTableData?> getEndorsementByHash(String sha256) {
    return (select(endorsementDocumentsTable)..where((t) => t.sha256.equals(sha256))).getSingleOrNull();
  }

  /// Inserts a new endorsement document.
  Future<void> insertEndorsement(EndorsementDocumentsTableCompanion document) {
    return into(endorsementDocumentsTable).insert(document);
  }

  /// Marks an existing document as superseded by [replacementDocument] within an atomic transaction.
  Future<void> supersedeEndorsement({
    required String originalId,
    required EndorsementDocumentsTableCompanion replacementDocument,
  }) {
    return transaction(() async {
      // 1. Insert replacement document
      await into(endorsementDocumentsTable).insert(replacementDocument);
      // 2. Mark original document as supersededBy replacement ID
      final replacementId = replacementDocument.id.value;
      await (update(endorsementDocumentsTable)..where((t) => t.id.equals(originalId)))
          .write(EndorsementDocumentsTableCompanion(
            supersededBy: Value(replacementId),
          ));
    });
  }

  /// Deletes an endorsement document.
  Future<int> deleteEndorsement(String id) {
    return (delete(endorsementDocumentsTable)..where((t) => t.id.equals(id))).go();
  }
}

