import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/presentation/providers/flights_providers.dart';
import 'package:aviation_logbook/features/shell/presentation/screens/app_navigation_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpShellAt(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        flightsStreamProvider.overrideWith(
          (ref) => Stream<List<Flight>>.value([]),
        ),
      ],
      child: const MaterialApp(home: AppNavigationShell()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phones get a bottom navigation bar', (tester) async {
    await _pumpShellAt(tester, const Size(390, 844));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('tablets get a compact navigation rail', (tester) async {
    await _pumpShellAt(tester, const Size(820, 1180));

    expect(find.byType(NavigationBar), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
  });

  testWidgets('desktops get a labelled, extended rail', (tester) async {
    await _pumpShellAt(tester, const Size(1440, 900));

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
  });

  testWidgets('More opens the drawer from the rail', (tester) async {
    await _pumpShellAt(tester, const Size(1440, 900));

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Backup & Restore'), findsOneWidget);
  });
}
