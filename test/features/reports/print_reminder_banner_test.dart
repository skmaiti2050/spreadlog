import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/domain/flight_time.dart';
import 'package:aviation_logbook/features/flights/domain/landings.dart';
import 'package:aviation_logbook/features/flights/presentation/providers/flights_providers.dart';
import 'package:aviation_logbook/features/reports/presentation/widgets/print_reminder_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Flight _flightLogged(DateTime createdAt) => Flight(
  id: 'f1',
  date: createdAt,
  registration: 'ZS-ABC',
  picName: 'SELF',
  flightTimes: const [
    FlightTime(
      aircraftClass: AircraftClass.singleEngine,
      period: TimePeriod.day,
      role: PilotRole.pic,
      durationMinutes: 60,
    ),
  ],
  landings: const Landings(dayCount: 1),
  createdAt: createdAt,
  updatedAt: createdAt,
);

Future<void> _pumpBanner(WidgetTester tester, List<Flight> flights) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Finite stream: an open one keeps the test isolate alive.
        flightsStreamProvider.overrideWith((ref) => Stream.value(flights)),
      ],
      child: const MaterialApp(home: Scaffold(body: PrintReminderBanner())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final oldEntry = _flightLogged(
    DateTime.now().subtract(const Duration(days: 120)),
  );

  testWidgets('shows when entries have gone 90 days unprinted', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _pumpBanner(tester, [oldEntry]);

    expect(find.text('Print now'), findsOneWidget);
  });

  testWidgets('Later hides it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpBanner(tester, [oldEntry]);

    await tester.tap(find.text('Later'));
    await tester.pump();

    expect(find.text('Print now'), findsNothing);
  });

  testWidgets('stays hidden after a recent print', (tester) async {
    SharedPreferences.setMockInitialValues({
      'spreadlog_logbook_last_printed_at': DateTime.now()
          .subtract(const Duration(days: 10))
          .toIso8601String(),
    });

    await _pumpBanner(tester, [oldEntry]);

    expect(find.text('Print now'), findsNothing);
  });
}
