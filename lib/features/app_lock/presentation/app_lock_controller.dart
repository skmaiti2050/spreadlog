import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/native_app_lock.dart';
import '../domain/app_lock.dart';

final appLockSupportedProvider = Provider<bool>(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);
final deviceAuthenticatorProvider = Provider<DeviceAuthenticator>(
  (ref) => NativeDeviceAuthenticator(),
);
final appLockSettingsStoreProvider = Provider<AppLockSettingsStore>(
  (ref) => const SecureAppLockSettingsStore(),
);
final appLockControllerProvider = Provider<AppLockController>((ref) {
  final controller = AppLockController(
    supported: ref.watch(appLockSupportedProvider),
    authenticator: ref.watch(deviceAuthenticatorProvider),
    store: ref.watch(appLockSettingsStoreProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

class AppLockController extends ChangeNotifier {
  final bool supported;
  final DeviceAuthenticator authenticator;
  final AppLockSettingsStore store;
  final DateTime Function() now;
  AppLockController({
    required this.supported,
    required this.authenticator,
    required this.store,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  AppLockPolicy policy = AppLockPolicy(const AppLockSettings());
  bool ready = false;
  bool busy = false;
  bool _foreground = true;
  Completer<void>? _foregroundWaiter;
  bool _disposed = false;
  String message = '';
  bool get covered =>
      !ready || policy.locked || (policy.settings.enabled && !_foreground);

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (busy || ready) return;
    busy = true;
    if (!supported) {
      ready = true;
      busy = false;
      _emit();
      return;
    }
    try {
      final settings = await store.load();
      await store.protectPreviews(settings.enabled);
      policy = AppLockPolicy(settings);
      ready = true;
      message = '';
    } catch (_) {
      message = 'Could not read device lock settings. Retry to keep your logbook protected.';
    }
    busy = false;
    _emit();
  }

  void inactive() {
    _foreground = false;
    _foregroundWaiter ??= Completer<void>();
    _emit();
  }

  void background() {
    _foreground = false;
    _foregroundWaiter ??= Completer<void>();
    // Native authentication may launch the device credential Activity. Its
    // lifecycle must not recursively lock or restart the authentication.
    if (!busy) policy.background(now());
    _emit();
  }

  void resumed() {
    _foreground = true;
    _foregroundWaiter?.complete();
    _foregroundWaiter = null;
    if (!busy) policy.resume(now());
    _emit();
  }

  Future<bool> _authenticate(String reason) async {
    final result = await authenticator.authenticate(reason);
    message = switch (result) {
      AuthenticationResult.success => '',
      AuthenticationResult.canceled =>
        'Authentication canceled. Tap Unlock to try again.',
      AuthenticationResult.unavailable => 'Set up a device PIN, password or biometrics in Android security settings, then try again.',
      AuthenticationResult.lockedOut => 'Device authentication is locked. Unlock your device with its PIN or password, then try again.',
      AuthenticationResult.failed => 'Device authentication failed. Try again.',
    };
    if (result != AuthenticationResult.success) return false;
    // Android may complete authentication before delivering resumed. Retain
    // the verified result, but keep content covered until the app is visible.
    if (!_foreground) await _foregroundWaiter!.future;
    return !_disposed && _foreground;
  }

  Future<void> unlock() async {
    if (!supported || !ready || busy || !_foreground) return;
    busy = true;
    _emit();
    try {
      if (await _authenticate('Unlock your Spreadlog logbook')) policy.unlock();
    } catch (_) {
      message = 'Device authentication failed. Try again.';
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> changeSettings(AppLockSettings settings) async {
    if (!supported || !ready || busy || covered) return;
    busy = true;
    _emit();
    try {
      if (!await _authenticate('Confirm changes to Spreadlog app lock')) return;
      // Protect the window before enabling, and remove protection only after
      // the disabled setting has been durably saved.
      if (settings.enabled) await store.protectPreviews(true);
      await store.save(settings);
      policy.settings = settings;
      policy.unlock();
      if (!settings.enabled) await store.protectPreviews(false);
      message = '';
    } catch (_) {
      message = 'Could not save app lock settings. Try again.';
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> openSecuritySettings() async {
    try {
      await authenticator.openSecuritySettings();
    } catch (_) {
      message = 'Open Android Settings, then Security, to configure device authentication.';
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _foregroundWaiter?.complete();
    _foregroundWaiter = null;
    super.dispose();
  }
}
