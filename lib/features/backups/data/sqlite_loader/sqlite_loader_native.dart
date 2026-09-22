import 'package:sqlite3/sqlite3.dart';

import 'sqlite_loader_interface.dart';

class NativeSqliteLoader implements SqliteLoader {
  @override
  Future<CommonSqlite3> load() async {
    return sqlite3;
  }
}

SqliteLoader getSqliteLoader() => NativeSqliteLoader();
