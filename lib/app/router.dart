import 'package:flutter/material.dart';

import '../features/endorsements/presentation/screens/endorsement_vault_screen.dart';
import '../features/flights/presentation/screens/flight_list_screen.dart';

class AppRouter {
  const AppRouter._();

  static const String initialRoute = '/';
  static const String endorsementsRoute = '/endorsements';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          builder: (_) => const FlightListScreen(),
          settings: settings,
        );
      case '/endorsements':
        return MaterialPageRoute<void>(
          builder: (_) => const EndorsementVaultScreen(),
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

