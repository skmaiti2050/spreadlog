import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/endorsements_dao.dart';
import '../domain/document_hasher.dart';
import '../domain/endorsement_category.dart';
import '../domain/endorsement_document.dart';
import '../domain/endorsements_repository_port.dart';
import 'document_storage/document_file_storage.dart';

class EndorsementsRepository implements EndorsementsRepositoryPort {
  final EndorsementsDao dao;
  final DocumentFileStorage _fileStorage;
  final DocumentHasher _hasher;

  EndorsementsRepository({
    required this.dao,
    DocumentFileStorage? fileStorage,
    DocumentHasher? hasher,
  })  : _fileStorage = fileStorage ?? getDocumentFileStorage(),
        _hasher = hasher ?? DocumentHasher();


  EndorsementDocument _mapToDomain(EndorsementDocumentsTableData row) {
    return EndorsementDocument(
      id: row.id,
      category: EndorsementCategory.fromCode(row.category),
      endorsementDate: row.endorsementDate,
      pageNumber: row.pageNumber,
      originalPath: row.originalPath,
      processedPath: row.processedPath,
      thumbnailPath: row.thumbnailPath,
      sha256: row.sha256,
      capturedAt: row.capturedAt,
      supersededBy: row.supersededBy,
      supersedes: row.supersedes,
      notes: row.notes,
    );
  }

  @override
  Stream<List<EndorsementDocument>> watchEndorsements({bool includeSuperseded = false}) {
    return dao
        .watchAllEndorsements(includeSuperseded: includeSuperseded)
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Future<List<EndorsementDocument>> getEndorsements({bool includeSuperseded = false}) async {
    final rows = await dao.getAllEndorsements(includeSuperseded: includeSuperseded);
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<EndorsementDocument?> getEndorsementById(String id) async {
    final row = await dao.getEndorsementById(id);
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<EndorsementDocument> saveEndorsement({
    required EndorsementCategory category,
    required DateTime endorsementDate,
    int? pageNumber,
    required List<int> imageBytes,
    required String fileExtension,
    String? notes,
    String? supersedesId,
  }) async {
    final id = 'end_${DateTime.now().millisecondsSinceEpoch}';
    final sha256 = await _hasher.computeSha256(Uint8List.fromList(imageBytes));
    final filePath = await _fileStorage.saveDocumentFile(
      id: id,
      fileExtension: fileExtension,
      bytes: imageBytes,
    );
    final now = DateTime.now();

    final companion = EndorsementDocumentsTableCompanion(
      id: Value(id),
      category: Value(category.code),
      endorsementDate: Value(endorsementDate),
      pageNumber: Value(pageNumber),
      originalPath: Value(filePath),
      sha256: Value(sha256),
      capturedAt: Value(now),
      supersedes: Value(supersedesId),
      notes: Value(notes),
    );

    if (supersedesId != null && supersedesId.isNotEmpty) {
      await dao.supersedeEndorsement(
        originalId: supersedesId,
        replacementDocument: companion,
      );
    } else {
      await dao.insertEndorsement(companion);
    }

    return EndorsementDocument(
      id: id,
      category: category,
      endorsementDate: endorsementDate,
      pageNumber: pageNumber,
      originalPath: filePath,
      sha256: sha256,
      capturedAt: now,
      supersedes: supersedesId,
      notes: notes,
    );
  }

  @override
  Future<bool> verifyIntegrity(String id) async {
    final row = await dao.getEndorsementById(id);
    if (row == null) return false;
    final bytes = await _fileStorage.readDocumentBytes(row.originalPath);
    if (bytes == null) return false;
    return await _hasher.verifySha256(Uint8List.fromList(bytes), row.sha256);
  }

  @override
  Future<void> deleteEndorsement(String id) async {
    final row = await dao.getEndorsementById(id);
    if (row != null) {
      await _fileStorage.deleteDocumentFile(row.originalPath);
      await dao.deleteEndorsement(id);
    }
  }

}

