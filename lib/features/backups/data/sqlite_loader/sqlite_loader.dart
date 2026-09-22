import 'sqlite_loader_interface.dart';
import 'sqlite_loader_stub.dart'
    if (dart.library.js_interop) 'sqlite_loader_web.dart'
    if (dart.library.io) 'sqlite_loader_native.dart';

SqliteLoader getPlatformSqliteLoader() => getSqliteLoader();

