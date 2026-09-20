abstract class DocumentFileStorage {
  Future<String> saveDocumentFile({
    required String id,
    required String fileExtension,
    required List<int> bytes,
  });

  Future<List<int>?> readDocumentBytes(String path);

  Future<void> deleteDocumentFile(String path);
}

