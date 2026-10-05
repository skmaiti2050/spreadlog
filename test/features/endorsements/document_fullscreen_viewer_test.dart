import 'package:aviation_logbook/features/endorsements/domain/endorsement_category.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_document.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_page.dart';
import 'package:aviation_logbook/features/endorsements/presentation/widgets/document_fullscreen_viewer.dart';
import 'package:aviation_logbook/features/endorsements/presentation/widgets/endorsement_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Finder button(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is IconButton && widget.tooltip == tooltip,
);

EndorsementDocument document({String? notes}) => EndorsementDocument(
  id: 'viewer',
  category: EndorsementCategory.tw,
  endorsementDate: DateTime(2026),
  capturedAt: DateTime(2026),
  notes: notes,
  originalPath: 'memory://first',
  sha256: 'a' * 64,
  storedPages: [
    EndorsementPage(originalPath: 'memory://first', sha256: 'a' * 64),
    EndorsementPage(originalPath: 'memory://second', sha256: 'b' * 64),
  ],
);

void main() {
  testWidgets('full view zooms, fits, and resets zoom when changing pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DocumentFullscreenViewer(document: document())),
    );
    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    await tester.tap(button('Zoom in'));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    for (var i = 0; i < 8; i++) {
      await tester.tap(button('Zoom in'));
      await tester.pump();
    }
    expect(controller.value.getMaxScaleOnAxis(), closeTo(8, 0.001));
    await tester.tap(button('Fit page'));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), 1);
    await tester.tap(button('Zoom in'));
    await tester.pump();
    await tester.tap(button('Next document page'));
    await tester.pump();
    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(controller.value.getMaxScaleOnAxis(), 1);
    expect(
      tester.widget<IconButton>(button('Next document page')).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('double tap enlarges the image and double tap again fits it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DocumentFullscreenViewer(document: document())),
    );
    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    final point = tester.getCenter(find.byType(InteractiveViewer));
    for (var i = 0; i < 2; i++) {
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), i == 0 ? 2.5 : 1);
    }
  });
  testWidgets(
    'full view opens at selected page and returns the viewed page to details',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EndorsementDetailsDialog(document: document()),
            ),
          ),
        ),
      );
      await tester.tap(button('Next document page'));
      await tester.pump();
      await tester.tap(button('Open full view'));
      await tester.pumpAndSettle();
      expect(find.byType(DocumentFullscreenViewer), findsOneWidget);
      expect(find.text('Page 2 of 2'), findsOneWidget);
      await tester.tap(button('Previous document page'));
      await tester.pump();
      await tester.tap(button('Close full view'));
      await tester.pumpAndSettle();
      expect(find.text('Page 1 of 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'mobile details scroll long notes while full view remains reachable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EndorsementDetailsDialog(
                document: document(notes: 'Long document notes. ' * 60),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(button('Open full view'));
      await tester.pumpAndSettle();
      expect(find.byType(DocumentFullscreenViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
