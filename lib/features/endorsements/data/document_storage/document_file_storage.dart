export 'document_file_storage_interface.dart';
export 'document_file_storage_stub.dart'
    if (dart.library.js_interop) 'document_file_storage_web.dart'
    if (dart.library.io) 'document_file_storage_native.dart';

