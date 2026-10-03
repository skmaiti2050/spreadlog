import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/aviation_theme.dart';
import '../features/backups/data/backup_intent_service.dart';
import '../features/backups/presentation/screens/backup_restore_screen.dart';
import 'router.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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
  @override
  void initState() {
    super.initState();
    BackupIntentService.initialize(
      onFileReceived: (filePath) {
        if (!BackupRestoreScreen.isScreenActive) {
          appNavigatorKey.currentState?.pushNamed(
            AppRouter.backupsRoute,
            arguments: filePath,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeMode = ref.watch(aviationThemeProvider);
    final themeData = AviationThemes.getThemeData(activeThemeMode);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Spreadlog',
      theme: themeData,
      scrollBehavior: const AppScrollBehavior(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.initialRoute,
    );
  }
}
