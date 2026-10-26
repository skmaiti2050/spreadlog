import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

import 'storage_status.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final db = await WasmDatabase.open(
      databaseName: 'aviation_logbook_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    // drift silently falls back to an in-memory database when no persistent
    // browser storage works; record the choice so the UI can warn the pilot.
    final status = StorageStatus(
      implementation: db.chosenImplementation.name,
      missingFeatures: [for (final f in db.missingFeatures) f.name],
      isPersistent:
          db.chosenImplementation != WasmStorageImplementation.inMemory,
    );
    storageStatus.value = status;
    debugPrint('Spreadlog web database: $status');

    return db.resolvedExecutor;
  });
}
