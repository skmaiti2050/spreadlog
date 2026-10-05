import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

import '../../domain/scanner/document_scanner_port.dart';

/// Platform-aware document scanner adapter.
/// Uses [cunning_document_scanner] on Android & iOS, with graceful fallback.
class DocumentScannerAdapter implements DocumentScannerPort {
  const DocumentScannerAdapter();

  @override
  Future<List<String>> getScannedImagePaths({
    bool manual = false,
    bool gallery = false,
  }) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      if (defaultTargetPlatform == TargetPlatform.android && !gallery) {
        return await const MethodChannel('com.spreadlog.app/scanner')
                .invokeListMethod<String>(
                  manual ? 'scanManual' : 'scanAutomatic',
                ) ??
            [];
      }
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        scannerSource: gallery
            ? ScannerSource.gallery
            : ScannerSource.cameraAndGallery,
      );
      return pictures ?? [];
    }
    throw UnsupportedError(
      'Document scanning is available on Android and iOS.',
    );
  }
}
