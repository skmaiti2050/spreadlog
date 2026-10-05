import 'dart:io';

import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/endorsements/data/endorsements_repository.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_category.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'endorsements_repository_test.dart' show InMemoryDocumentFileStorage;

void main() {
  test('version 4 single image migrates as one page without changing its identity or hash', () async {
    final directory = await Directory.systemTemp.createTemp('group_migration_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/logbook.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    addTearDown(() => db.close());
    final storage = InMemoryDocumentFileStorage();
    final doc =
        await EndorsementsRepository(
          dao: db.endorsementsDao,
          fileStorage: storage,
        ).saveEndorsement(
          category: EndorsementCategory.tw,
          endorsementDate: DateTime(2026),
          imageBytes: [1, 2],
          fileExtension: 'jpg',
        );
    await db.customStatement(
      'ALTER TABLE endorsement_documents_table DROP COLUMN pages_json',
    );
    await db.customStatement('PRAGMA user_version = 4');
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    final repo = EndorsementsRepository(
      dao: db.endorsementsDao,
      fileStorage: storage,
    );
    final restored = (await repo.getEndorsements()).single;
    expect(restored.id, doc.id);
    expect(restored.pageCount, 1);
    expect(restored.sha256, doc.sha256);
    expect(restored.documentHash, isNull);
    expect(await repo.verifyIntegrity(restored.id), isTrue);
  });
}
