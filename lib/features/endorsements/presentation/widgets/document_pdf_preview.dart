import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class DocumentPdfPreview extends StatelessWidget {
  final Uint8List bytes;
  final String filename;

  const DocumentPdfPreview({
    super.key,
    required this.bytes,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Document PDF')),
    body: PdfPreview(
      build: (_) async => bytes,
      pdfFileName: filename,
      canChangeOrientation: false,
      canChangePageFormat: false,
      allowPrinting: true,
      allowSharing: true,
    ),
  );
}
