import 'package:sqlite3/wasm.dart';

import 'sqlite_loader_interface.dart';

class WebSqliteLoader implements SqliteLoader {
  @override
  Future<CommonSqlite3> load() async {
    return await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  }
}

SqliteLoader getSqliteLoader() => WebSqliteLoader();
