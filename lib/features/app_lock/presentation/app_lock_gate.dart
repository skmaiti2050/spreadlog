import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backups/data/backup_intent_service.dart';
import 'app_lock_controller.dart';

class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  late final AppLockController _lock;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _lock = ref.read(appLockControllerProvider);
    WidgetsBinding.instance.addObserver(this);
    _lock.addListener(_changed);
    BackupIntentService.setDeliveryPaused(_lock.supported);
    unawaited(_lock.initialize());
  }

  void _changed() {
    if (!mounted) return;
    if (!_lock.covered) _opened = true;
    setState(() {});
    // Navigation is available after this frame, including the first unlock.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) BackupIntentService.setDeliveryPaused(_lock.covered);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _lock.resumed();
      case AppLifecycleState.inactive:
        _lock.inactive();
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _lock.background();
      case AppLifecycleState.detached:
        _lock.background();
    }
    if (_lock.covered) BackupIntentService.setDeliveryPaused(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lock.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final covered = _lock.covered;
    if (!_lock.ready && _lock.message.isEmpty) {
      return const Scaffold(
        body: SafeArea(child: Center(child: Text('Opening Spreadlog…'))),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_opened)
          Offstage(
            offstage: covered,
            child: TickerMode(enabled: !covered, child: widget.child),
          ),
        if (covered)
          PopScope(
            canPop: false,
            child: Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 40),
                          const SizedBox(height: 20),
                          Text(
                            _lock.ready
                                ? 'Spreadlog is locked'
                                : 'Opening Spreadlog',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _lock.message.isEmpty
                                ? 'Use your device fingerprint, face, PIN or password to continue.'
                                : _lock.message,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _lock.busy
                                ? null
                                : () {
                                    unawaited(
                                      _lock.ready
                                          ? _lock.unlock()
                                          : _lock.initialize(),
                                    );
                                  },
                            child: Text(
                              _lock.busy
                                  ? 'Authenticating…'
                                  : _lock.ready
                                  ? 'Unlock'
                                  : 'Retry',
                            ),
                          ),
                          if (_lock.ready)
                            TextButton(
                              onPressed: _lock.busy
                                  ? null
                                  : () =>
                                        unawaited(_lock.openSecuritySettings()),
                              child: const Text('Android security settings'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
