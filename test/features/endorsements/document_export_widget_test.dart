import 'dart:async';
import 'dart:typed_data';

import 'package:aviation_logbook/features/endorsements/data/document_pdf_exporter.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_document.dart';
import 'package:aviation_logbook/features/endorsements/presentation/providers/endorsements_providers.dart';
import 'package:aviation_logbook/features/endorsements/presentation/widgets/endorsement_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'document_fullscreen_viewer_test.dart' show document;

class PendingExporter extends DocumentPdfExporter {
  final result = Completer<Uint8List>();
  int calls = 0;
  @override
  Future<Uint8List> export(EndorsementDocument document) {
    calls++;
    return result.future;
  }
}

void main() {
  testWidgets(
    'export prevents duplicate requests and reports failure without leaving details',
    (tester) async {
      final exporter = PendingExporter();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [documentPdfExporterProvider.overrideWithValue(exporter)],
          child: MaterialApp(
            home: Scaffold(
              body: EndorsementDetailsDialog(document: document()),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Export PDF'));
      await tester.tap(find.text('Export PDF'));
      await tester.pump();
      expect(find.text('Preparing PDF...'), findsOneWidget);
      final exportButton = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Preparing PDF...'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(exportButton.onPressed, isNull);
      expect(exporter.calls, 1);
      exporter.result.completeError(
        StateError('An original document page is missing.'),
      );
      await tester.pump();
      expect(
        find.text('An original document page is missing.'),
        findsOneWidget,
      );
      expect(find.byType(EndorsementDetailsDialog), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
