import 'package:aviation_logbook/features/flights/domain/flight_filter.dart';
import 'package:aviation_logbook/features/flights/presentation/widgets/flight_filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feedback_domain_test.dart' show flight;

void main() {
  testWidgets(
    'phone filter dialog combines registrations and applies a period',
    (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      FlightFilter? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await FlightFilterDialog.show(
                    context,
                    initial: const FlightFilter(),
                    flights: [
                      flight('a', DateTime(2026), registration: 'ZS-ABC'),
                      flight('b', DateTime(2026), registration: 'ZS-XYZ'),
                    ],
                  );
                },
                child: const Text('Filters'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 12 months'));
      await tester.tap(find.text('ZS-ABC'));
      await tester.tap(find.text('ZS-XYZ'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(selected?.registrations, {'ZS-ABC', 'ZS-XYZ'});
      expect(selected?.startDate, FlightFilter.yearBefore(DateTime.now()));
      expect(selected?.endDate, FlightFilter.day(DateTime.now()));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'calendar-year presets clamp leap day and totals include final-day times',
    () {
      expect(
        FlightFilter.yearBefore(DateTime(2024, 2, 29)),
        DateTime(2023, 2, 28),
      );
      final selected =
          FlightFilter(
            startDate: DateTime(2024, 2, 29),
            endDate: DateTime(2024, 2, 29),
          ).apply([
            flight('in', DateTime(2024, 2, 29, 23, 59)),
            flight('out', DateTime(2024, 3, 1)),
          ]);
      expect(selected.map((flight) => flight.id), ['in']);
    },
  );
}
