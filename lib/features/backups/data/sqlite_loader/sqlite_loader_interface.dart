import 'package:sqlite3/common.dart';

abstract class SqliteLoader {
  Future<CommonSqlite3> load();
}

