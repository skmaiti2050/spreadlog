import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/endorsements_dao.dart';
import '../domain/document_hasher.dart';
import '../domain/endorsement_category.dart';
import '../domain/endorsement_document.dart';
import '../domain/endorsement_page.dart';
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
  }) : _fileStorage = fileStorage ?? getDocumentFileStorage(),
       _hasher = hasher ?? DocumentHasher();

  EndorsementDocument _mapToDomain(EndorsementDocumentsTableData row) {
    final manifest = row.pagesJson == null
        ? null
        : jsonDecode(row.pagesJson!) as Map<String, dynamic>;
    if (manifest != null &&
        (manifest['version'] != 1 ||
            manifest['sha256'] is! String ||
            (manifest['pages'] as List<dynamic>).isEmpty)) {
      throw const FormatException(
        'Unsupported or empty document page manifest',
      );
    }
    return EndorsementDocument(
      storedPages: manifest == null
          ? const []
          : List.unmodifiable(
              (manifest['pages'] as List<dynamic>).map(
                (p) => EndorsementPage.fromJson(p as Map<String, dynamic>),
              ),
            ),
      documentHash: manifest?['sha256'] as String?,
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
  Stream<List<EndorsementDocument>> watchEndorsements({
    bool includeSuperseded = false,
  }) {
    return dao
        .watchAllEndorsements(includeSuperseded: includeSuperseded)
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Future<List<EndorsementDocument>> getEndorsements({
    bool includeSuperseded = false,
  }) async {
    final rows = await dao.getAllEndorsements(
      includeSuperseded: includeSuperseded,
    );
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
    return saveDocument(
      category: category,
      endorsementDate: endorsementDate,
      pageNumber: pageNumber,
      pages: [
        DocumentPageInput(imageBytes: imageBytes, fileExtension: fileExtension),
      ],
      notes: notes,
      supersedesId: supersedesId,
    );
  }

  @override
  Future<EndorsementDocument> saveDocument({
    required EndorsementCategory category,
    required DateTime endorsementDate,
    required List<DocumentPageInput> pages,
    int? pageNumber,
    String? notes,
    String? supersedesId,
  }) async {
    if (pages.isEmpty || pages.any((p) => p.imageBytes.isEmpty)) {
      throw ArgumentError('A document must contain non-empty page images');
    }
    final inputs = List<DocumentPageInput>.unmodifiable(pages);
    final random = Random.secure();
    final suffix = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final id = 'end_${DateTime.now().microsecondsSinceEpoch}_$suffix';
    final saved = <EndorsementPage>[];
    final attemptedPaths = <String>[];
    final now = DateTime.now();
    try {
      for (var i = 0; i < inputs.length; i++) {
        final page = inputs[i];
        final hash = await _hasher.computeSha256(
          Uint8List.fromList(page.imageBytes),
        );
        final path = await _fileStorage.saveDocumentFile(
          id: '${id}_page${i + 1}',
          fileExtension: page.fileExtension,
          bytes: page.imageBytes,
        );
        attemptedPaths.add(path);
        saved.add(
          EndorsementPage(
            originalPath: path,
            sha256: hash,
            pageNumber: i == 0 ? pageNumber : null,
          ),
        );
      }
      final documentHash = await _hasher.computeDocumentHash(
        saved.map((p) => p.sha256).toList(),
      );
      final companion = EndorsementDocumentsTableCompanion(
        id: Value(id),
        category: Value(category.code),
        endorsementDate: Value(endorsementDate),
        pageNumber: Value(pageNumber),
        originalPath: Value(saved.first.originalPath),
        sha256: Value(saved.first.sha256),
        capturedAt: Value(now),
        supersedes: Value(supersedesId),
        notes: Value(notes),
        pagesJson: Value(
          jsonEncode({
            'version': 1,
            'sha256': documentHash,
            'pages': saved.map((p) => p.toJson()).toList(),
          }),
        ),
      );
      await dao.transaction(() async {
        if (supersedesId != null && supersedesId.isNotEmpty) {
          final original = await dao.getEndorsementById(supersedesId);
          if (original == null || original.supersededBy != null) {
            throw StateError(
              'Only an existing active document can be replaced',
            );
          }
          await dao.supersedeEndorsement(
            originalId: supersedesId,
            replacementDocument: companion,
          );
        } else {
          await dao.insertEndorsement(companion);
        }
      });
      return EndorsementDocument(
        id: id,
        category: category,
        endorsementDate: endorsementDate,
        pageNumber: pageNumber,
        originalPath: saved.first.originalPath,
        sha256: saved.first.sha256,
        capturedAt: now,
        notes: notes,
        supersedes: supersedesId,
        storedPages: List.unmodifiable(saved),
        documentHash: documentHash,
      );
    } catch (_) {
      // Metadata and superseding links remain unpublished on failure.
      // Preserve the original exception even if cleanup itself fails.
      for (final path in attemptedPaths) {
        try {
          await _fileStorage.deleteDocumentFile(path);
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<bool> verifyIntegrity(String id) async {
    final document = await getEndorsementById(id);
    if (document == null) return false;
    for (final page in document.pages) {
      final bytes = await _fileStorage.readDocumentBytes(page.originalPath);
      if (bytes == null ||
          !await _hasher.verifySha256(Uint8List.fromList(bytes), page.sha256)) {
        return false;
      }
    }
    final hash = document.documentHash;
    return hash == null ||
        hash ==
            await _hasher.computeDocumentHash(
              document.pages.map((p) => p.sha256).toList(),
            );
  }

  @override
  Future<void> deleteEndorsement(String id) async {
    final document = await getEndorsementById(id);
    if (document != null) {
      // Delete metadata first so a failed DB operation never leaves a visible broken group.
      await dao.deleteEndorsement(id);
      for (final page in document.pages) {
        await _fileStorage.deleteDocumentFile(page.originalPath);
      }
    }
  }
}
