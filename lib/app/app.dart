import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/aviation_theme.dart';
import 'router.dart';


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

class AviationLogbookApp extends ConsumerWidget {
  const AviationLogbookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeThemeMode = ref.watch(aviationThemeProvider);
    final themeData = AviationThemes.getThemeData(activeThemeMode);

    return MaterialApp(
      title: 'Spreadlog',
      theme: themeData,
      scrollBehavior: const AppScrollBehavior(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.initialRoute,
    );
  }
}
