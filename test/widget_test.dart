import 'package:aviation_logbook/app/app.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/presentation/providers/flights_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:aviation_logbook/features/splash/presentation/screens/splash_screen.dart';
import 'package:aviation_logbook/app/router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.spreadlog.app/backup_intent'),
          (call) async => null,
        );
  });

  testWidgets('App smoke test shows splash and navigates to flight deck', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flightsStreamProvider.overrideWith(
            (ref) => Stream<List<Flight>>.value([]),
          ),
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
    expect(find.byTooltip('Select Multiple'), findsNothing);
    expect(find.byTooltip('Select All'), findsNothing);
    expect(find.byTooltip('Delete Selected'), findsNothing);
  });

  testWidgets('Cold backup launch opens restore above home exactly once', (
    tester,
  ) async {
    var pendingRequests = 0;
    const backupPath = '/cached/test.spbackup';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.spreadlog.app/backup_intent'),
          (call) async {
            if (call.method == 'getPendingBackupPath') {
              pendingRequests++;
              return backupPath;
            }
            return null;
          },
        );
    final openedRoutes = <RouteSettings>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flightsStreamProvider.overrideWith(
            (ref) => Stream<List<Flight>>.value([]),
          ),
        ],
        child: MaterialApp(
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            openedRoutes.add(settings);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  const Scaffold(body: Text('Restore incoming backup')),
            );
          },
        ),
      ),
    );
    // Skip and then advance through the original timer: it must not navigate twice.
    await tester.tap(find.text('Spreadlog'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Restore incoming backup'), findsOneWidget);
    expect(openedRoutes, hasLength(1));
    expect(openedRoutes.single.name, AppRouter.backupsRoute);
    expect(openedRoutes.single.arguments, backupPath);
    expect(pendingRequests, 1);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('TOTAL FLIGHT TIME'), findsOneWidget);
  });
}
