import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_pdf_preview.dart';

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
    body: AppPdfPreview(buildPdf: (_) async => bytes, fileName: filename),
  );
}
