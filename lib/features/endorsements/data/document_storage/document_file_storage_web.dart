import 'dart:convert';

import 'document_file_storage_interface.dart';

class WebDocumentFileStorage implements DocumentFileStorage {
  @override
  Future<String> saveDocumentFile({
    required String id,
    required String fileExtension,
    required List<int> bytes,
  }) async {
    final cleanExt = fileExtension.replaceAll('.', '').toLowerCase();
    final mime = cleanExt == 'png'
        ? 'image/png'
        : cleanExt == 'pdf'
            ? 'application/pdf'
            : 'image/jpeg';
    final base64String = base64Encode(bytes);
    return 'data:$mime;base64,$base64String';
  }

  @override
  Future<List<int>?> readDocumentBytes(String path) async {
    if (path.startsWith('data:')) {
      final commaIndex = path.indexOf(',');
      if (commaIndex != -1) {
        final data = path.substring(commaIndex + 1);
        return base64Decode(data);
      }
    }
    return null;
  }

  @override
  Future<void> deleteDocumentFile(String path) async {
    // Data URLs are stored in the database, no-op on filesystem
  }
}

DocumentFileStorage getDocumentFileStorage() => WebDocumentFileStorage();

