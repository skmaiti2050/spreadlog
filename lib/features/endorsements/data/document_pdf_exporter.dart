import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/document_hasher.dart';
import '../domain/endorsement_document.dart';
import 'document_storage/document_file_storage.dart';

/// Produces a viewing/printing copy without changing the captured originals.
class DocumentPdfExporter {
  final DocumentFileStorage _storage;
  final DocumentHasher _hasher;

  DocumentPdfExporter({DocumentFileStorage? storage, DocumentHasher? hasher})
    : _storage = storage ?? getDocumentFileStorage(),
      _hasher = hasher ?? DocumentHasher();

  Future<Uint8List> export(EndorsementDocument document) async {
    final fingerprint = document.documentHash;
    if (fingerprint != null &&
        fingerprint !=
            await _hasher.computeDocumentHash(
              document.pages.map((page) => page.sha256).toList(),
            )) {
      throw StateError('Document page order failed integrity verification.');
    }
    final pdf = pw.Document(
      title: document.category.label,
      author: 'Spreadlog',
    );
    for (final page in document.pages) {
      final bytes = await _storage.readDocumentBytes(page.originalPath);
      if (bytes == null) {
        throw StateError('An original document page is missing.');
      }
      final imageBytes = Uint8List.fromList(bytes);
      if (!await _hasher.verifySha256(imageBytes, page.sha256)) {
        throw StateError(
          'An original document page failed integrity verification.',
        );
      }
      final image = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: (image.width ?? 0) > (image.height ?? 0)
              ? PdfPageFormat.a4.landscape
              : PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(12),
          build: (_) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }
    return pdf.save();
  }
}
