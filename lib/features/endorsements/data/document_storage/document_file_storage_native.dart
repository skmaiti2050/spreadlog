import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'document_file_storage_interface.dart';

class NativeDocumentFileStorage implements DocumentFileStorage {
  @override
  Future<String> saveDocumentFile({
    required String id,
    required String fileExtension,
    required List<int> bytes,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final endorsementsDir = Directory(p.join(docsDir.path, 'endorsements'));
    if (!await endorsementsDir.exists()) {
      await endorsementsDir.create(recursive: true);
    }
    final cleanExt = fileExtension.startsWith('.') ? fileExtension : '.$fileExtension';
    final file = File(p.join(endorsementsDir.path, '$id$cleanExt'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<List<int>?> readDocumentBytes(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  @override
  Future<void> deleteDocumentFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

DocumentFileStorage getDocumentFileStorage() => NativeDocumentFileStorage();

