import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/aircraft/presentation/providers/aircraft_providers.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/presentation/providers/flights_providers.dart';
import 'package:aviation_logbook/features/flights/presentation/widgets/log_flight_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> openEntry(
  WidgetTester tester,
  void Function(Flight?) saved,
) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final date = DateTime(2026, 1);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        flightsStreamProvider.overrideWith(
          (ref) => Stream.value([
            Flight(
              id: 'previous',
              date: date,
              aircraftModelId: 'C172',
              registration: 'ZS-ABC',
              picName: 'SELF',
              hobbsStartTenths: 54860,
              hobbsEndTenths: 54867,
              createdAt: date,
              updatedAt: date,
            ),
          ]),
        ),
        allAircraftModelsProvider.overrideWith(
          (ref) => Stream.value(<AircraftModel>[]),
        ),
        allModelEndorsementsProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved(
                  await Navigator.of(context).push<Flight>(
                    MaterialPageRoute<Flight>(
                      builder: (_) => const LogFlightDialog(isFullScreen: true),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(field('Aircraft model / type'));
  await tester.enterText(field('Aircraft model / type'), 'C172');
  await tester.ensureVisible(field('Aircraft Registration'));
  await tester.enterText(field('Aircraft Registration'), 'ZS-ABC');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Hobbs prefill and direct elapsed default save the original readings',
    (tester) async {
      Flight? saved;
      await openEntry(tester, (flight) => saved = flight);
      await tester.ensureVisible(field('Aircraft model / type'));
      await tester.enterText(field('Aircraft model / type'), 'ONEOFF');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hobbs readings'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('Hobbs start')).controller?.text,
        '5486.7',
      );
      await tester.ensureVisible(field('Hobbs end'));
      await tester.enterText(field('Hobbs end'), '5488.2');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(field('Total Flight Duration'))
            .controller
            ?.text,
        '01:30',
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Flight'));
      await tester.pumpAndSettle();
      expect(saved?.aircraftModelId, 'ONEOFF');
      expect(saved?.totalDurationMinutes, 90);
      expect(saved?.hobbsStartTenths, 54867);
      expect(saved?.hobbsEndTenths, 54882);
      expect(saved?.durationSource, 'hobbs');
    },
  );

  testWidgets(
    'decimal entry rejects extra precision and saves integer minutes',
    (tester) async {
      Flight? saved;
      await openEntry(tester, (flight) => saved = flight);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Decimal hours'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Decimal hours (e.g. 1.5)'), '1.25');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter whole hours or one decimal digit'),
        findsOneWidget,
      );
      await tester.ensureVisible(field('Decimal hours (e.g. 1.5)'));
      await tester.enterText(field('Decimal hours (e.g. 1.5)'), '1.6');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Flight'));
      await tester.pumpAndSettle();
      expect(saved?.totalDurationMinutes, 96);
      expect(saved?.durationSource, 'decimal');
    },
  );
}
