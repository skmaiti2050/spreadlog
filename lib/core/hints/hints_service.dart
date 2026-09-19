import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HintsState {
  final Set<String> dismissedHints;
  final bool hintsEnabled;

  const HintsState({
    required this.dismissedHints,
    required this.hintsEnabled,
  });

  HintsState copyWith({
    Set<String>? dismissedHints,
    bool? hintsEnabled,
  }) {
    return HintsState(
      dismissedHints: dismissedHints ?? this.dismissedHints,
      hintsEnabled: hintsEnabled ?? this.hintsEnabled,
    );
  }

  bool isVisible(String hintKey) {
    return hintsEnabled && !dismissedHints.contains(hintKey);
  }
}

class HintsNotifier extends Notifier<HintsState> {
  static const _prefDismissedKey = 'spreadlog_dismissed_hints';
  static const _prefEnabledKey = 'spreadlog_hints_enabled';

  @override
  HintsState build() {
    _loadPreferences();
    return const HintsState(dismissedHints: {}, hintsEnabled: true);
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedList = prefs.getStringList(_prefDismissedKey) ?? [];
      final enabled = prefs.getBool(_prefEnabledKey) ?? true;
      state = HintsState(
        dismissedHints: dismissedList.toSet(),
        hintsEnabled: enabled,
      );
    } catch (_) {}
  }

  Future<void> dismiss(String hintKey) async {
    final updated = Set<String>.from(state.dismissedHints)..add(hintKey);
    state = state.copyWith(dismissedHints: updated);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefDismissedKey, updated.toList());
    } catch (_) {}
  }

  Future<void> setHintsEnabled(bool enabled) async {
    state = state.copyWith(hintsEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefEnabledKey, enabled);
    } catch (_) {}
  }

  Future<void> resetAllHints() async {
    state = state.copyWith(dismissedHints: {});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefDismissedKey);
    } catch (_) {}
  }
}

final hintsProvider = NotifierProvider<HintsNotifier, HintsState>(
  HintsNotifier.new,
);

