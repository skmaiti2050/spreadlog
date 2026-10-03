import 'package:flutter/material.dart';

import '../features/backups/presentation/screens/backup_restore_screen.dart';
import '../features/endorsements/presentation/screens/endorsement_vault_screen.dart';
import '../features/shell/presentation/screens/app_navigation_shell.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  const AppRouter._();

  static const String initialRoute = '/';
  static const String flightsRoute = '/flights';
  static const String endorsementsRoute = '/endorsements';
  static const String backupsRoute = '/backups';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case '/flights':
        return MaterialPageRoute<void>(
          builder: (_) => const AppNavigationShell(),
          settings: settings,
        );
      case '/endorsements':
        return MaterialPageRoute<void>(
          builder: (_) => const EndorsementVaultScreen(),
          settings: settings,
        );
      case '/backups':
        final filePath = settings.arguments as String?;
        return MaterialPageRoute<void>(
          builder: (_) => BackupRestoreScreen(initialFilePath: filePath),
          settings: settings,
        );

      default:
        return MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }
}

