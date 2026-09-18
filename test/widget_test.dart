import 'package:aviation_logbook/app/app.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/presentation/providers/flights_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flightsStreamProvider.overrideWith((ref) => Stream<List<Flight>>.value([])),
        ],
        child: const AviationLogbookApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Aviation Logbook'), findsOneWidget);
    expect(find.text('TOTAL FLIGHT TIME'), findsOneWidget);
  });
}
