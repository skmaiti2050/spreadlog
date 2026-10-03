import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the currently selected tab index for the main navigation shell:
/// 0: Flights Deck
/// 1: Physical Logbook
/// 2: Endorsement Vault
/// 3: Aircraft Register (Fleet)
class NavigationTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) {
    if (index >= 0 && index <= 3) {
      state = index;
    }
  }
}

final navigationTabProvider =
    NotifierProvider<NavigationTabNotifier, int>(NavigationTabNotifier.new);
