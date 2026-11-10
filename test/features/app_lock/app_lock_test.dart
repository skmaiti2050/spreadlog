import 'dart:async';

import 'package:aviation_logbook/features/app_lock/domain/app_lock.dart';
import 'package:aviation_logbook/features/app_lock/presentation/app_lock_controller.dart';
import 'package:aviation_logbook/features/app_lock/presentation/app_lock_gate.dart';
import 'package:aviation_logbook/features/app_lock/presentation/app_lock_navigation_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthenticator implements DeviceAuthenticator {
  AuthenticationResult result = AuthenticationResult.success;
  Completer<AuthenticationResult>? pending;
  int calls = 0;
  @override
  Future<AuthenticationResult> authenticate(String reason) async {
    calls++;
    return pending == null ? result : await pending!.future;
  }

  @override
  Future<void> openSecuritySettings() async {}
}

class FakeStore implements AppLockSettingsStore {
  AppLockSettings settings;
  bool fail = false;
  final protected = <bool>[];
  FakeStore([this.settings = const AppLockSettings(enabled: true)]);
  @override
  Future<AppLockSettings> load() async {
    if (fail) throw StateError('unavailable');
    return settings;
  }

  @override
  Future<void> save(AppLockSettings value) async {
    if (fail) throw StateError('unavailable');
    settings = value;
  }

  @override
  Future<void> protectPreviews(bool value) async {
    protected.add(value);
  }
}

class PendingStore extends FakeStore {
  final loaded = Completer<AppLockSettings>();
  @override
  Future<AppLockSettings> load() => loaded.future;
}

void main() {
  final start = DateTime(2026, 11, 10);
  for (final delay in RelockDelay.values) {
    test('startup and timeout boundary: ${delay.name}', () {
      final policy = AppLockPolicy(
        AppLockSettings(enabled: true, delay: delay),
      );
      expect(policy.locked, isTrue);
      policy.unlock();
      policy.background(start);
      // Duplicate hidden/paused events must not move the start time.
      policy.background(start.add(const Duration(seconds: 30)));
      policy.resume(start.add(delay.duration));
      expect(policy.locked, isTrue);
      if (delay != RelockDelay.immediately) {
        policy.unlock();
        policy.background(start);
        policy.resume(
          start.add(delay.duration - const Duration(milliseconds: 1)),
        );
        expect(policy.locked, isFalse);
      }
      policy.unlock();
      policy.background(start);
      policy.resume(start.subtract(const Duration(seconds: 1)));
      expect(policy.locked, isTrue);
    });
  }
  test('disabled lock never relocks', () {
    final policy = AppLockPolicy(const AppLockSettings());
    policy.background(start);
    policy.resume(start.add(const Duration(days: 1)));
    expect(policy.locked, isFalse);
  });
  test(
    'authentication failure, cancellation and lockout cannot unlock',
    () async {
      final auth = FakeAuthenticator();
      final store = FakeStore();
      final lock = AppLockController(
        supported: true,
        authenticator: auth,
        store: store,
      );
      addTearDown(lock.dispose);
      await lock.initialize();
      for (final result in AuthenticationResult.values.where(
        (r) => r != AuthenticationResult.success,
      )) {
        auth.result = result;
        await lock.unlock();
        expect(lock.covered, isTrue);
      }
      auth.result = AuthenticationResult.success;
      await lock.unlock();
      expect(lock.covered, isFalse);
      expect(store.protected, [true]);
    },
  );
  test('settings require successful authentication and storage failures stay protected', () async {
    final auth = FakeAuthenticator();
    final store = FakeStore(const AppLockSettings());
    final lock = AppLockController(
      supported: true,
      authenticator: auth,
      store: store,
    );
    addTearDown(lock.dispose);
    await lock.initialize();
    auth.result = AuthenticationResult.canceled;
    await lock.changeSettings(const AppLockSettings(enabled: true));
    expect(store.settings.enabled, isFalse);
    auth.result = AuthenticationResult.success;
    await lock.changeSettings(const AppLockSettings(enabled: true));
    expect(store.settings.enabled, isTrue);
    auth.result = AuthenticationResult.canceled;
    await lock.changeSettings(const AppLockSettings());
    expect(store.settings.enabled, isTrue);
    auth.result = AuthenticationResult.success;
    store.fail = true;
    await lock.changeSettings(const AppLockSettings());
    expect(lock.policy.settings.enabled, isTrue);
    expect(store.protected.last, isTrue);
  });
  test(
    'authentication lifecycle does not prompt twice or unlock on cancellation',
    () async {
      final auth = FakeAuthenticator()..pending = Completer();
      final lock = AppLockController(
        supported: true,
        authenticator: auth,
        store: FakeStore(),
      );
      addTearDown(lock.dispose);
      await lock.initialize();
      final attempt = lock.unlock();
      lock.inactive();
      lock.background();
      lock.resumed();
      await lock.unlock();
      expect(auth.calls, 1);
      auth.pending!.complete(AuthenticationResult.canceled);
      await attempt;
      expect(lock.covered, isTrue);
      expect(lock.busy, isFalse);
      auth.pending = null;
      await lock.unlock();
      expect(lock.covered, isFalse);
    },
  );
  test(
    'settings read failure stays covered; web never invokes native APIs',
    () async {
      final store = FakeStore()..fail = true;
      final auth = FakeAuthenticator();
      final lock = AppLockController(
        supported: true,
        authenticator: auth,
        store: store,
      );
      addTearDown(lock.dispose);
      await lock.initialize();
      expect(lock.covered, isTrue);
      expect(lock.ready, isFalse);
      final web = AppLockController(
        supported: false,
        authenticator: auth,
        store: store,
      );
      addTearDown(web.dispose);
      await web.initialize();
      expect(web.covered, isFalse);
      expect(auth.calls, 0);
    },
  );
  test(
    'successful settings authentication waits for the resumed lifecycle',
    () async {
      final auth = FakeAuthenticator()..pending = Completer();
      final store = FakeStore(const AppLockSettings());
      final lock = AppLockController(
        supported: true,
        authenticator: auth,
        store: store,
      );
      addTearDown(lock.dispose);
      await lock.initialize();
      expect(auth.calls, 0);
      expect(lock.policy.settings.enabled, isFalse);
      final change = lock.changeSettings(const AppLockSettings(enabled: true));
      lock.inactive();
      auth.pending!.complete(AuthenticationResult.success);
      await Future<void>.delayed(Duration.zero);
      expect(store.settings.enabled, isFalse);
      expect(lock.busy, isTrue);
      lock.resumed();
      await change;
      expect(store.settings.enabled, isTrue);
      expect(auth.calls, 1);
    },
  );

  testWidgets(
    'fresh startup shows no authentication UI or prompt while loading',
    (tester) async {
      final auth = FakeAuthenticator();
      final store = PendingStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLockSupportedProvider.overrideWithValue(true),
            deviceAuthenticatorProvider.overrideWithValue(auth),
            appLockSettingsStoreProvider.overrideWithValue(store),
          ],
          child: const MaterialApp(
            home: AppLockGate(child: Scaffold(body: Text('Logbook'))),
          ),
        ),
      );
      expect(find.text('Opening Spreadlog…'), findsOneWidget);
      expect(find.textContaining('fingerprint'), findsNothing);
      expect(find.text('Authenticating…'), findsNothing);
      expect(auth.calls, 0);
      store.loaded.complete(const AppLockSettings());
      await tester.pumpAndSettle();
      expect(find.text('Logbook'), findsOneWidget);
      expect(auth.calls, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('enabled lock authenticates automatically on launch and return', (
    tester,
  ) async {
    final auth = FakeAuthenticator();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockSupportedProvider.overrideWithValue(true),
          deviceAuthenticatorProvider.overrideWithValue(auth),
          appLockSettingsStoreProvider.overrideWithValue(FakeStore()),
        ],
        child: const MaterialApp(
          home: AppLockGate(child: Scaffold(body: Text('Logbook'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(auth.calls, 1);
    expect(find.text('Logbook'), findsOneWidget);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(auth.calls, 2);
    expect(find.text('Logbook'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'returning from canceled automatic authentication does not reprompt',
    (tester) async {
      final auth = FakeAuthenticator()..pending = Completer();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLockSupportedProvider.overrideWithValue(true),
            deviceAuthenticatorProvider.overrideWithValue(auth),
            appLockSettingsStoreProvider.overrideWithValue(FakeStore()),
          ],
          child: const MaterialApp(
            home: AppLockGate(child: Scaffold(body: Text('Logbook'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(auth.calls, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      auth.pending!.complete(AuthenticationResult.canceled);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(auth.calls, 1);
      expect(find.text('Logbook'), findsNothing);
      expect(find.text('Unlock'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('gate hides startup content and preserves input through relock', (
    tester,
  ) async {
    final auth = FakeAuthenticator()..result = AuthenticationResult.canceled;
    final store = FakeStore();
    final input = TextEditingController();
    addTearDown(input.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockSupportedProvider.overrideWithValue(true),
          deviceAuthenticatorProvider.overrideWithValue(auth),
          appLockSettingsStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          home: AppLockGate(
            child: Scaffold(
              body: Column(
                children: [
                  const Text('Private logbook'),
                  TextField(controller: input),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private logbook'), findsNothing);
    auth.result = AuthenticationResult.success;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'unfinished');
    auth.result = AuthenticationResult.canceled;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('Private logbook'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Private logbook'), findsNothing);
    expect(auth.calls, 3);
    auth.result = AuthenticationResult.success;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(input.text, 'unfinished');
    expect(find.text('Private logbook'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('system Back cannot pop a route behind the locked gate', (
    tester,
  ) async {
    final auth = FakeAuthenticator()..result = AuthenticationResult.canceled;
    final lock = AppLockController(
      supported: true,
      authenticator: auth,
      store: FakeStore(),
    );
    final observer = AppLockNavigationObserver(lock);
    addTearDown(observer.dispose);
    addTearDown(lock.dispose);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLockControllerProvider.overrideWithValue(lock)],
        child: MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [observer],
          builder: (context, child) => AppLockGate(child: child!),
          home: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    auth.result = AuthenticationResult.success;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Unfinished entry')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    lock.background();
    lock.resumed();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isTrue);
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Unfinished entry'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
