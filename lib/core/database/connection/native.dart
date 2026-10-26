import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'storage_status.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(dbFolder.path, 'database'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final file = File(p.join(dbDir.path, 'app_database.sqlite'));
    storageStatus.value = const StorageStatus(
      implementation: 'native',
      isPersistent: true,
    );
    return NativeDatabase.createInBackground(file);
  });
}

