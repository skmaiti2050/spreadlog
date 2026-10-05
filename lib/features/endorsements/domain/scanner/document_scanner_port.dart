/// Pure Dart port interface for scanning or picking document images.
abstract interface class DocumentScannerPort {
  /// Captures or imports one or more document images, returning their file paths.
  Future<List<String>> getScannedImagePaths({
    bool manual = false,
    bool gallery = false,
  });
}
