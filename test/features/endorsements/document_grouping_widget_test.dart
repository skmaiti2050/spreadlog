import 'package:aviation_logbook/features/endorsements/domain/endorsement_category.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_document.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_page.dart';
import 'package:aviation_logbook/features/endorsements/presentation/widgets/endorsement_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'group viewer navigates ordered pages and disables end controls',
    (tester) async {
      final doc = EndorsementDocument(
        id: 'group',
        category: EndorsementCategory.tw,
        endorsementDate: DateTime(2026),
        capturedAt: DateTime(2026),
        originalPath: 'memory://first',
        sha256: 'first-hash',
        documentHash: 'group-hash',
        storedPages: const [
          EndorsementPage(originalPath: 'memory://first', sha256: 'first-hash'),
          EndorsementPage(
            originalPath: 'memory://second',
            sha256: 'second-hash',
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: EndorsementDetailsDialog(document: doc)),
          ),
        ),
      );
      expect(find.text('Page 1 of 2'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Previous document page'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Next document page'));
      await tester.pump();
      expect(find.text('Page 2 of 2'), findsOneWidget);
      expect(find.text('second-hash'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Next document page'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Previous document page'));
      await tester.pump();
      expect(find.text('Page 1 of 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
