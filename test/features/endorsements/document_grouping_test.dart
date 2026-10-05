import 'dart:convert';

import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/endorsements/data/endorsements_repository.dart';
import 'package:aviation_logbook/features/endorsements/domain/document_hasher.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_category.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_document.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_page.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'endorsements_repository_test.dart' show InMemoryDocumentFileStorage;

class FailingStorage extends InMemoryDocumentFileStorage {
  int? failAt;
  int writes = 0;
  @override
  Future<String> saveDocumentFile({
    required String id,
    required String fileExtension,
    required List<int> bytes,
  }) {
    writes++;
    if (writes == failAt) throw StateError('disk full');
    return super.saveDocumentFile(
      id: id,
      fileExtension: fileExtension,
      bytes: bytes,
    );
  }
}

void main() {
  late AppDatabase db;
  late FailingStorage storage;
  late EndorsementsRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    storage = FailingStorage();
    repo = EndorsementsRepository(
      dao: db.endorsementsDao,
      fileStorage: storage,
    );
  });
  tearDown(() async => db.close());
  Future<EndorsementDocument> save({String? replaces}) => repo.saveDocument(
    category: EndorsementCategory.tw,
    endorsementDate: DateTime(2026, 10, 5),
    pageNumber: 12,
    pages: [
      for (var i = 1; i <= 3; i++)
        DocumentPageInput(imageBytes: [i, 10], fileExtension: 'jpg'),
    ],
    supersedesId: replaces,
  );

  test(
    'one document preserves ordered pages, source numbers and JSON',
    () async {
      final doc = await save();
      expect(await repo.getEndorsements(), hasLength(1));
      expect(doc.pages.map((p) => p.pageNumber), [12, null, null]);
      expect(storage.storage, hasLength(3));
      expect((await repo.getEndorsementById(doc.id))!.pages, doc.pages);
      expect(EndorsementDocument.fromJson(doc.toJson()), doc);
      expect(() => doc.storedPages.clear(), throwsUnsupportedError);
      expect(await repo.verifyIntegrity(doc.id), isTrue);
    },
  );
  test(
    'tampering with a later page fails whole document verification',
    () async {
      final doc = await save();
      storage.storage[doc.pages.last.originalPath] = [99];
      expect(await repo.verifyIntegrity(doc.id), isFalse);
    },
  );
  test('missing later page fails whole document verification', () async {
    final doc = await save();
    storage.storage.remove(doc.pages.last.originalPath);
    expect(await repo.verifyIntegrity(doc.id), isFalse);
  });
  test('changing page order invalidates the document fingerprint', () async {
    final doc = await save();
    final row = await db.endorsementsDao.getEndorsementById(doc.id);
    final manifest = jsonDecode(row!.pagesJson!) as Map<String, dynamic>;
    manifest['pages'] = (manifest['pages'] as List).reversed.toList();
    await db.customStatement(
      'UPDATE endorsement_documents_table SET pages_json = ? WHERE id = ?',
      [jsonEncode(manifest), doc.id],
    );
    expect(await repo.verifyIntegrity(doc.id), isFalse);
  });
  test(
    'failed page write cleans files and publishes no partial document',
    () async {
      storage.failAt = 2;
      await expectLater(save(), throwsStateError);
      expect(storage.storage, isEmpty);
      expect(await repo.getEndorsements(), isEmpty);
    },
  );
  test(
    'failed replacement preserves every original page and active record',
    () async {
      final original = await save();
      storage.failAt = 5;
      await expectLater(save(replaces: original.id), throwsStateError);
      expect((await repo.getEndorsements()).map((d) => d.id), [original.id]);
      expect(storage.storage, hasLength(3));
      expect(await repo.verifyIntegrity(original.id), isTrue);
    },
  );
  test('replacement retains original group and links one new group', () async {
    final original = await save();
    final replacement = await save(replaces: original.id);
    expect((await repo.getEndorsements()).map((d) => d.id), [replacement.id]);
    expect(await repo.getEndorsements(includeSuperseded: true), hasLength(2));
    expect(
      (await repo.getEndorsementById(original.id))!.supersededBy,
      replacement.id,
    );
    expect(storage.storage, hasLength(6));
    expect(await repo.verifyIntegrity(original.id), isTrue);
  });
  test('failed metadata publication cleans all newly written pages', () async {
    await expectLater(save(replaces: 'missing'), throwsStateError);
    expect(storage.storage, isEmpty);
    expect(await repo.getEndorsements(), isEmpty);
  });
  test('deleting a group deletes all of its page files', () async {
    final doc = await save();
    await repo.deleteEndorsement(doc.id);
    expect(await repo.getEndorsements(), isEmpty);
    expect(storage.storage, isEmpty);
  });
  test(
    'fingerprint distinguishes order and page count deterministically',
    () async {
      final hasher = DocumentHasher();
      final hash = await hasher.computeDocumentHash(['a', 'b']);
      expect(await hasher.computeDocumentHash(['a', 'b']), hash);
      expect(await hasher.computeDocumentHash(['b', 'a']), isNot(hash));
      expect(await hasher.computeDocumentHash(['a']), isNot(hash));
    },
  );
}
