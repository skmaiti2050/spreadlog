import 'package:aviation_logbook/core/database/connection/storage_status.dart';
import 'package:aviation_logbook/core/widgets/storage_warning_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpWith(WidgetTester tester, StorageStatus? status) async {
    storageStatus.value = status;
    addTearDown(() => storageStatus.value = null);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StorageWarningBanner())),
    );
  }

  testWidgets('hidden while the database is persistent', (tester) async {
    await pumpWith(
      tester,
      const StorageStatus(
        implementation: 'sharedIndexedDb',
        isPersistent: true,
      ),
    );

    expect(find.byIcon(Icons.warning_amber), findsNothing);
  });

  testWidgets('warns when drift fell back to memory', (tester) async {
    await pumpWith(
      tester,
      const StorageStatus(implementation: 'inMemory', isPersistent: false),
    );

    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
  });
}
