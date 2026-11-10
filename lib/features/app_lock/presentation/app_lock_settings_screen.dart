import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_lock.dart';
import 'app_lock_controller.dart';

class AppLockSettingsScreen extends ConsumerWidget {
  const AppLockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockControllerProvider);
    return ListenableBuilder(
      listenable: lock,
      builder: (context, _) {
        final settings = lock.policy.settings;
        return Scaffold(
          appBar: AppBar(title: const Text('App lock')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Protect access to this logbook with your Android device authentication. This setting stays on this device.',
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Require device authentication'),
                subtitle: const Text('Fingerprint, face, PIN or password'),
                value: settings.enabled,
                onChanged: lock.busy
                    ? null
                    : (enabled) => unawaited(
                        lock.changeSettings(AppLockSettings(enabled: enabled)),
                      ),
              ),
              if (settings.enabled) ...[
                const SizedBox(height: 16),
                Text(
                  'Lock after leaving the app',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RelockDelay>(
                  initialValue: settings.delay,
                  key: ValueKey(settings.delay),
                  decoration: const InputDecoration(labelText: 'Relock delay'),
                  items: const [
                    DropdownMenuItem(
                      value: RelockDelay.immediately,
                      child: Text('Immediately'),
                    ),
                    DropdownMenuItem(
                      value: RelockDelay.oneMinute,
                      child: Text('After 1 minute'),
                    ),
                    DropdownMenuItem(
                      value: RelockDelay.fiveMinutes,
                      child: Text('After 5 minutes'),
                    ),
                  ],
                  onChanged: lock.busy
                      ? null
                      : (delay) {
                          if (delay != null) {
                            unawaited(
                              lock.changeSettings(
                                AppLockSettings(enabled: true, delay: delay),
                              ),
                            );
                          }
                        },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recent-app previews are hidden while app lock is enabled. Scheduled encrypted backups continue while locked.',
                ),
              ],
              if (lock.message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(lock.message),
                ),
              TextButton(
                onPressed: lock.busy
                    ? null
                    : () => unawaited(lock.openSecuritySettings()),
                child: const Text('Android security settings'),
              ),
            ],
          ),
        );
      },
    );
  }
}
