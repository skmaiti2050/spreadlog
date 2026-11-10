import 'package:flutter/material.dart';

import 'app_lock_controller.dart';

/// Blocks system-back navigation on every route, including dialogs pushed
/// directly by widgets. The privacy gate itself sits above the Navigator.
class AppLockNavigationObserver extends NavigatorObserver {
  final AppLockController lock;
  final _entry = _LockPopEntry();
  final _routes = <ModalRoute<Object?>>{};

  AppLockNavigationObserver(this.lock) {
    lock.addListener(_changed);
    _changed();
  }

  void _changed() => _entry.canPopNotifier.value = !lock.covered;

  void _register(Route<dynamic> route) {
    if (route is ModalRoute<Object?> && _routes.add(route)) {
      route.registerPopEntry(_entry);
    }
  }

  void _unregister(Route<dynamic> route) {
    if (route is ModalRoute<Object?> && _routes.remove(route)) {
      route.unregisterPopEntry(_entry);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _register(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _unregister(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _unregister(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _unregister(oldRoute);
    if (newRoute != null) _register(newRoute);
  }

  void dispose() {
    lock.removeListener(_changed);
    for (final route in _routes) {
      route.unregisterPopEntry(_entry);
    }
    _routes.clear();
    _entry.canPopNotifier.dispose();
  }
}

class _LockPopEntry extends PopEntry<Object?> {
  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier(false);

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {}
}
