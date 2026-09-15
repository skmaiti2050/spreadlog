import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbDir = Directory(p.join(dbFolder.path, 'database'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      final file = File(p.join(dbDir.path, 'app_database.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}

