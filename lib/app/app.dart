import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/aviation_theme.dart';
import '../features/app_lock/presentation/app_lock_gate.dart';
import '../features/app_lock/presentation/app_lock_controller.dart';
import '../features/app_lock/presentation/app_lock_navigation_observer.dart';
import '../features/backups/data/backup_intent_service.dart';
import '../features/backups/presentation/screens/backup_restore_screen.dart';
import 'router.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class AviationLogbookApp extends ConsumerStatefulWidget {
  const AviationLogbookApp({super.key});

  @override
  ConsumerState<AviationLogbookApp> createState() => _AviationLogbookAppState();
}

class _AviationLogbookAppState extends ConsumerState<AviationLogbookApp> {
  late final AppLockNavigationObserver _lockNavigation;

  @override
  void initState() {
    super.initState();
    _lockNavigation = AppLockNavigationObserver(
      ref.read(appLockControllerProvider),
    );
    BackupIntentService.setDeliveryPaused(ref.read(appLockSupportedProvider));
    BackupIntentService.initialize(
      onFileReceived: (filePath) {
        if (!BackupRestoreScreen.isScreenActive) {
          appNavigatorKey.currentState?.pushNamed(
            AppRouter.backupsRoute,
            arguments: filePath,
          );
        }
      },
      onInvalidFile: () {
        appMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              'That file is not a Spreadlog backup (.spbackup), so nothing was opened.',
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _lockNavigation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeMode = ref.watch(aviationThemeProvider);
    final themeData = AviationThemes.getThemeData(activeThemeMode);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      navigatorObservers: [_lockNavigation],
      scaffoldMessengerKey: appMessengerKey,
      title: 'Spreadlog',
      theme: themeData,
      scrollBehavior: const AppScrollBehavior(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.initialRoute,
      builder: (context, child) => AppLockGate(child: child!),
    );
  }
}
