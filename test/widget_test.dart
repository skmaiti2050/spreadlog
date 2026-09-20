import 'package:aviation_logbook/app/app.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/presentation/providers/flights_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(find.text('Aviation Logbook'), findsOneWidget);

    // Advance past splash transition (1400ms + transition)
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL FLIGHT TIME'), findsOneWidget);
  });
}
