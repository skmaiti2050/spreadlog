import 'package:aviation_logbook/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AviationLogbookApp(),
      ),
    );

    expect(find.text('Aviation Logbook'), findsOneWidget);
  });
}
