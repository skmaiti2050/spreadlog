import 'dart:io';

import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version 3 upgrade creates correction history and preserves existing aircraft', () async {
    final directory = await Directory.systemTemp.createTemp(
      'spreadlog_migration_',
    );
    final file = File('${directory.path}/logbook.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    try {
      await db.aircraftDao.getAllModels();
      // Recreate the previous version's schema: the only v4 addition is history.
      await db.customStatement('DROP TABLE endorsement_corrections');
      await db.customStatement(
        'ALTER TABLE endorsement_documents_table DROP COLUMN pages_json',
      );
      await db.customStatement('PRAGMA user_version = 3');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect(await db.aircraftDao.getModelById('C172'), isNotNull);
      expect(
        await db.customSelect('SELECT * FROM endorsement_corrections').get(),
        isEmpty,
      );
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .data['user_version'],
        5,
      );
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
}
