import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/widgets/aviation_app_drawer.dart';
import '../../../aircraft/presentation/screens/aircraft_register_screen.dart';
import '../../../endorsements/presentation/screens/endorsement_vault_screen.dart';
import '../../../flights/presentation/screens/flight_list_screen.dart';
import '../../../flights/presentation/screens/physical_logbook_screen.dart';
import '../providers/navigation_providers.dart';

/// Root shell widget hosting the primary operational tabs.
///
/// Features:
/// - IndexedStack to preserve scroll state & search filters with 0ms tab switching latency.
/// - Bottom NavigationBar on phones, NavigationRail on tablets (labelled on
///   desktop), with Flights, Physical Logbook, Vault, Fleet, and More.
/// - Integrated AviationAppDrawer triggered via hamburger button, left swipe, or More.
/// - PopScope handling on Android to navigate back to Tab 0 before app exit.
class AppNavigationShell extends ConsumerStatefulWidget {
  const AppNavigationShell({super.key});

  @override
  ConsumerState<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _Destination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String tooltip;

  const _Destination(this.icon, this.selectedIcon, this.label, this.tooltip);
}

class _AppNavigationShellState extends ConsumerState<AppNavigationShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<int> _activatedTabs = {0};

  static const List<Widget> _screens = [
    FlightListScreen(),
    PhysicalLogbookScreen(),
    EndorsementVaultScreen(),
    AircraftRegisterScreen(),
  ];

  /// Tabs first, then "More", which opens the drawer instead of a tab.
  static const List<_Destination> _destinations = [
    _Destination(
      Icons.flight_takeoff_outlined,
      Icons.flight_takeoff,
      'Flights',
      'Flight Deck & Log Entries',
    ),
    _Destination(
      Icons.menu_book_outlined,
      Icons.menu_book,
      'Logbook',
      'Physical SACAA Ledger Spread',
    ),
    _Destination(
      Icons.folder_special_outlined,
      Icons.folder_special,
      'Vault',
      'Endorsement Stamps & Signatures',
    ),
    _Destination(
      Icons.airplanemode_active_outlined,
      Icons.airplanemode_active,
      'Fleet',
      'Aircraft Register & Classes',
    ),
    _Destination(
      Icons.menu,
      Icons.menu,
      'More',
      'Open Tools, Reports & Settings Drawer',
    ),
  ];

  static const int _moreIndex = 4;

  void _onDestinationSelected(int index) {
    if (index == _moreIndex) {
      _scaffoldKey.currentState?.openDrawer();
    } else {
      ref.read(navigationTabProvider.notifier).selectTab(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(navigationTabProvider);
    final theme = Theme.of(context);
    final windowSize = WindowSize.of(context);

    if (!_activatedTabs.contains(activeTab)) {
      _activatedTabs.add(activeTab);
    }

    final tabs = IndexedStack(
      index: activeTab,
      children: List.generate(_screens.length, (index) {
        // Each tab gets its own messenger so its snackbars show inside the
        // tab's Scaffold and lift that Scaffold's FAB, instead of covering
        // it from this outer Scaffold.
        return _activatedTabs.contains(index)
            ? ScaffoldMessenger(child: _screens[index])
            : const SizedBox.shrink();
      }),
    );

    final body = PopScope(
      canPop: activeTab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (activeTab != 0) {
          ref.read(navigationTabProvider.notifier).selectTab(0);
        }
      },
      child: windowSize == WindowSize.compact
          ? tabs
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: activeTab,
                  onDestinationSelected: _onDestinationSelected,
                  extended: windowSize == WindowSize.expanded,
                  labelType: windowSize == WindowSize.expanded
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  backgroundColor: theme.colorScheme.surface,
                  indicatorColor: theme.colorScheme.primaryContainer,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Tooltip(message: d.tooltip, child: Icon(d.icon)),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: tabs),
              ],
            ),
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AviationAppDrawer(),
      body: body,
      bottomNavigationBar: windowSize == WindowSize.compact
          ? NavigationBar(
              selectedIndex: activeTab,
              onDestinationSelected: _onDestinationSelected,
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: theme.colorScheme.primaryContainer,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                    tooltip: d.tooltip,
                  ),
              ],
            )
          : null,
    );
  }
}
