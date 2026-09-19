import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported aviation themes compliant with night vision retention and high-contrast cockpit readability.
enum AviationThemeMode {
  cockpitDark,
  deepNavy,
  sunlightLight;

  String get displayName {
    switch (this) {
      case AviationThemeMode.cockpitDark:
        return 'Cockpit Dark (Night Vision)';
      case AviationThemeMode.deepNavy:
        return 'Deep Navy (Oceanic)';
      case AviationThemeMode.sunlightLight:
        return 'Sunlight Light (High Contrast)';
    }
  }

  IconData get icon {
    switch (this) {
      case AviationThemeMode.cockpitDark:
        return Icons.nightlight_round;
      case AviationThemeMode.deepNavy:
        return Icons.dark_mode;
      case AviationThemeMode.sunlightLight:
        return Icons.light_mode;
    }
  }
}

class AviationThemeNotifier extends Notifier<AviationThemeMode> {
  static const _prefKey = 'spreadlog_theme_mode';

  @override
  AviationThemeMode build() {
    // Load initial preference asynchronously in background
    _loadFromPrefs();
    return AviationThemeMode.cockpitDark; // Default to aviation dark for glare reduction
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null) {
        final mode = AviationThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => AviationThemeMode.cockpitDark,
        );
        state = mode;
      }
    } catch (_) {}
  }

  Future<void> setTheme(AviationThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode.name);
    } catch (_) {}
  }

  void cycleNext() {
    final nextIndex = (state.index + 1) % AviationThemeMode.values.length;
    setTheme(AviationThemeMode.values[nextIndex]);
  }
}

final aviationThemeProvider =
    NotifierProvider<AviationThemeNotifier, AviationThemeMode>(
  AviationThemeNotifier.new,
);

class AviationThemes {
  const AviationThemes._();

  static ThemeData getThemeData(AviationThemeMode mode) {
    switch (mode) {
      case AviationThemeMode.cockpitDark:
        return _cockpitDarkTheme;
      case AviationThemeMode.deepNavy:
        return _deepNavyTheme;
      case AviationThemeMode.sunlightLight:
        return _sunlightLightTheme;
    }
  }

  static ThemeData get _cockpitDarkTheme {
    const bg = Color(0xFF101418);
    const surface = Color(0xFF171D22);
    const surfaceHighest = Color(0xFF222B33);
    const primary = Color(0xFF4A90E2);
    const outline = Color(0xFF384552);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1E2E3E),
        onPrimaryContainer: Color(0xFFD6E4FF),
        secondary: Color(0xFF64B5F6),
        onSecondary: Color(0xFF001E36),
        secondaryContainer: Color(0xFF1E3348),
        onSecondaryContainer: Color(0xFFBAE3FF),
        surface: surface,
        onSurface: Color(0xFFE2E6EB),
        onSurfaceVariant: Color(0xFFA2ACB8),
        surfaceContainerHighest: surfaceHighest,
        outline: outline,
        outlineVariant: Color(0xFF2A343E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF2C353D)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHighest,
        side: const BorderSide(color: Color(0xFF2C353D)),
        labelStyle: const TextStyle(color: Color(0xFFE2E6EB), fontSize: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFBAE3FF);
            }
            return const Color(0xFFA2ACB8);
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF1E3348);
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.all(const BorderSide(color: Color(0xFF2C353D))),
        ),
      ),
    );
  }

  static ThemeData get _deepNavyTheme {
    const bg = Color(0xFF0A1118);
    const surface = Color(0xFF101D28);
    const surfaceHighest = Color(0xFF182A3A);
    const primary = Color(0xFF00B4D8);
    const outline = Color(0xFF284865);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Color(0xFF001E2B),
        primaryContainer: Color(0xFF122C42),
        onPrimaryContainer: Color(0xFFCAF0F8),
        secondary: Color(0xFF90E0EF),
        onSecondary: Color(0xFF001F28),
        secondaryContainer: Color(0xFF183850),
        onSecondaryContainer: Color(0xFFBBE9F9),
        surface: surface,
        onSurface: Color(0xFFE0EBF2),
        onSurfaceVariant: Color(0xFF9CB5C8),
        surfaceContainerHighest: surfaceHighest,
        outline: outline,
        outlineVariant: Color(0xFF1E3A52),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF1E3A52)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHighest,
        side: const BorderSide(color: Color(0xFF1E3A52)),
        labelStyle: const TextStyle(color: Color(0xFFE0EBF2), fontSize: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFCAF0F8);
            }
            return const Color(0xFF9CB5C8);
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF122C42);
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.all(const BorderSide(color: Color(0xFF1E3A52))),
        ),
      ),
    );
  }

  static ThemeData get _sunlightLightTheme {
    const bg = Color(0xFFF6F8FA);
    const surface = Color(0xFFFFFFFF);
    const surfaceHighest = Color(0xFFEEF2F6);
    const primary = Color(0xFF1565C0);
    const outline = Color(0xFF8C959F);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD6E4FF),
        onPrimaryContainer: Color(0xFF001B3E),
        secondary: Color(0xFF0D47A1),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE3EDF7),
        onSecondaryContainer: Color(0xFF082747),
        surface: surface,
        onSurface: Color(0xFF1F2328),
        onSurfaceVariant: Color(0xFF424A53),
        surfaceContainerHighest: surfaceHighest,
        outline: outline,
        outlineVariant: Color(0xFFD0D7DE),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: Color(0xFF1F2328),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFD0D7DE)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHighest,
        side: const BorderSide(color: Color(0xFFD0D7DE)),
        labelStyle: const TextStyle(color: Color(0xFF1F2328), fontSize: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF0D47A1);
            }
            return const Color(0xFF424A53);
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFE3EDF7);
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.all(const BorderSide(color: Color(0xFFD0D7DE))),
        ),
      ),
    );
  }
}
