import 'package:flutter/foundation.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

import '../../domain/scanner/document_scanner_port.dart';

/// Platform-aware document scanner adapter.
/// Uses [cunning_document_scanner] on Android & iOS, with graceful fallback.
class DocumentScannerAdapter implements DocumentScannerPort {
  const DocumentScannerAdapter();

  @override
  Future<List<String>> getScannedImagePaths() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final pictures = await CunningDocumentScanner.getPictures();
        return pictures ?? [];
      } catch (e) {
        debugPrint('Document scanner invocation failed: $e');
        return [];
      }
    }
    return [];
  }
}

