import 'package:aviation_logbook/app/app.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/presentation/providers/flights_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.spreadlog.app/backup_intent'),
      (call) async => null,
    );
  });

  testWidgets('App smoke test shows splash and navigates to flight deck', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flightsStreamProvider.overrideWith((ref) => Stream<List<Flight>>.value([])),
        ],
        child: const AviationLogbookApp(),
      ),
    );

    // Initial splash frame
    await tester.pump();
    expect(find.text('Spreadlog'), findsOneWidget);

    // Advance past splash timer (1400ms)
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL FLIGHT TIME'), findsOneWidget);
  });
}
