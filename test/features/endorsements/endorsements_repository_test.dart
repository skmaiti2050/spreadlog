import 'dart:convert';
import 'dart:typed_data';
import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/endorsements/data/document_storage/document_file_storage_interface.dart';
import 'package:aviation_logbook/features/endorsements/data/endorsements_repository.dart';
import 'package:aviation_logbook/features/endorsements/domain/document_hasher.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_category.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryDocumentFileStorage implements DocumentFileStorage {
  final Map<String, List<int>> storage = {};

  @override
  Future<String> saveDocumentFile({
    required String id,
    required String fileExtension,
    required List<int> bytes,
  }) async {
    final path = 'memory://$id.$fileExtension';
    storage[path] = List.from(bytes);
    return path;
  }

  @override
  Future<List<int>?> readDocumentBytes(String path) async {
    return storage[path];
  }

  @override
  Future<void> deleteDocumentFile(String path) async {
    storage.remove(path);
  }
}

void main() {
  late AppDatabase db;
  late InMemoryDocumentFileStorage fileStorage;
  late EndorsementsRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fileStorage = InMemoryDocumentFileStorage();
    repository = EndorsementsRepository(dao: db.endorsementsDao, fileStorage: fileStorage);
  });

  tearDown(() async {
    await db.close();
  });

  group('EndorsementsRepository & EndorsementsDao Integration Tests', () {
    test('saveEndorsement stores document metadata, computes SHA-256 and writes to storage', () async {
      final endorsementBytes = utf8.encode('CERTIFIED LOGBOOK ENDORSEMENT: TAILWHEEL RATING SIGNED CFI 12345');
      final expectedSha256 = await DocumentHasher().computeSha256(Uint8List.fromList(endorsementBytes));
      final endorsementDate = DateTime(2026, 8, 15);


      final created = await repository.saveEndorsement(
        category: EndorsementCategory.tw,
        endorsementDate: endorsementDate,
        pageNumber: 12,
        imageBytes: endorsementBytes,
        fileExtension: 'jpg',
        notes: 'Signed by Capt. Miller CFI #12345',
      );

      expect(created.id, startsWith('end_'));
      expect(created.category, EndorsementCategory.tw);
      expect(created.endorsementDate, endorsementDate);
      expect(created.pageNumber, 12);
      expect(created.sha256, expectedSha256);
      expect(created.notes, 'Signed by Capt. Miller CFI #12345');
      expect(created.isSuperseded, isFalse);

      final all = await repository.getEndorsements();
      expect(all.length, 1);
      expect(all.first.id, created.id);

      // Verify integrity check passes with original bytes
      final isIntact = await repository.verifyIntegrity(created.id);
      expect(isIntact, isTrue);
    });

    test('tamper detection: verifyIntegrity returns false if stored bytes are corrupted', () async {
      final endorsementBytes = utf8.encode('ORIGINAL SIGNATURE VALID');
      final created = await repository.saveEndorsement(
        category: EndorsementCategory.vp,
        endorsementDate: DateTime(2026, 8, 10),
        imageBytes: endorsementBytes,
        fileExtension: 'jpg',
      );

      // Verify intact initially
      expect(await repository.verifyIntegrity(created.id), isTrue);

      // Tamper with the stored bytes
      fileStorage.storage[created.originalPath] = utf8.encode('MODIFIED FORGERY ATTEMPT');

      // Verify integrity check fails
      expect(await repository.verifyIntegrity(created.id), isFalse);
    });

    test('supersede endorsement atomically links predecessor and successor records', () async {
      final origBytes = utf8.encode('ORIGINAL INSTRUMENT RATING SCAN');
      final original = await repository.saveEndorsement(
        category: EndorsementCategory.instrumentRating,
        endorsementDate: DateTime(2025, 1, 10),
        imageBytes: origBytes,
        fileExtension: 'png',
        notes: 'Initial scan 2025',
      );

      expect(original.isSuperseded, isFalse);

      final replacementBytes = utf8.encode('HIGH RES RE-SCAN INSTRUMENT RATING 2026');
      final replacement = await repository.saveEndorsement(
        category: EndorsementCategory.instrumentRating,
        endorsementDate: DateTime(2025, 1, 10),
        imageBytes: replacementBytes,
        fileExtension: 'png',
        notes: 'Re-scanned at higher resolution with official CAA stamp',
        supersedesId: original.id,
      );

      expect(replacement.supersedes, original.id);

      // Fetch active endorsements only (exclude superseded)
      final activeOnly = await repository.getEndorsements(includeSuperseded: false);
      expect(activeOnly.length, 1);
      expect(activeOnly.first.id, replacement.id);

      // Fetch all endorsements (including superseded audit trail)
      final all = await repository.getEndorsements(includeSuperseded: true);
      expect(all.length, 2);

      final reloadedOriginal = await repository.getEndorsementById(original.id);
      expect(reloadedOriginal!.isSuperseded, isTrue);
      expect(reloadedOriginal.supersededBy, replacement.id);
    });

    test('deleteEndorsement removes metadata from database and deletes binary file', () async {
      final bytes = utf8.encode('TEMPORARY TEST ENDORSEMENT');
      final doc = await repository.saveEndorsement(
        category: EndorsementCategory.other,
        endorsementDate: DateTime(2026, 9, 1),
        imageBytes: bytes,
        fileExtension: 'jpg',
      );

      expect(fileStorage.storage.containsKey(doc.originalPath), isTrue);

      await repository.deleteEndorsement(doc.id);

      expect(await repository.getEndorsementById(doc.id), isNull);
      expect(fileStorage.storage.containsKey(doc.originalPath), isFalse);
    });
  });
}
