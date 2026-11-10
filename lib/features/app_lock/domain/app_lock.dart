enum RelockDelay {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5));

  const RelockDelay(this.duration);
  final Duration duration;
}

class AppLockSettings {
  final bool enabled;
  final RelockDelay delay;
  const AppLockSettings({
    this.enabled = false,
    this.delay = RelockDelay.immediately,
  });
}

enum AuthenticationResult { success, canceled, unavailable, lockedOut, failed }

abstract interface class DeviceAuthenticator {
  Future<AuthenticationResult> authenticate(String reason);
  Future<void> openSecuritySettings();
}

abstract interface class AppLockSettingsStore {
  Future<AppLockSettings> load();
  Future<void> save(AppLockSettings settings);
  Future<void> protectPreviews(bool enabled);
}

/// Pure policy; a new process always starts locked when protection is enabled.
class AppLockPolicy {
  AppLockSettings settings;
  bool locked;
  DateTime? _backgroundedAt;

  AppLockPolicy(this.settings) : locked = settings.enabled;

  void unlock() {
    locked = false;
    _backgroundedAt = null;
  }

  void background(DateTime now) {
    _backgroundedAt ??= now;
    if (settings.enabled && settings.delay == RelockDelay.immediately) {
      locked = true;
    }
  }

  void resume(DateTime now) {
    final since = _backgroundedAt;
    if (settings.enabled &&
        since != null &&
        (now.isBefore(since) ||
            now.difference(since) >= settings.delay.duration)) {
      locked = true;
    }
    _backgroundedAt = null;
  }
}
