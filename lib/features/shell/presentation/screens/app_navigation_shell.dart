import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/aviation_app_drawer.dart';
import '../../../aircraft/presentation/screens/aircraft_register_screen.dart';
import '../../../endorsements/presentation/screens/endorsement_vault_screen.dart';
import '../../../flights/presentation/screens/flight_list_screen.dart';
import '../../../flights/presentation/screens/physical_logbook_screen.dart';
import '../providers/navigation_providers.dart';

/// Root shell widget hosting the bottom navigation bar and primary operational tabs.
///
/// Features:
/// - IndexedStack to preserve scroll state & search filters with 0ms tab switching latency.
/// - NavigationBar with quick access to Flights, Physical Logbook, Vault, Fleet, and More.
/// - Integrated AviationAppDrawer triggered via hamburger button, left swipe, or More tab.
/// - PopScope handling on Android to navigate back to Tab 0 before app exit.
class AppNavigationShell extends ConsumerStatefulWidget {
  const AppNavigationShell({super.key});

  @override
  ConsumerState<AppNavigationShell> createState() => _AppNavigationShellState();
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

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(navigationTabProvider);
    final theme = Theme.of(context);

    if (!_activatedTabs.contains(activeTab)) {
      _activatedTabs.add(activeTab);
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AviationAppDrawer(),
      body: PopScope(
        canPop: activeTab == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (activeTab != 0) {
            ref.read(navigationTabProvider.notifier).selectTab(0);
          }
        },
        child: IndexedStack(
          index: activeTab,
          children: List.generate(_screens.length, (index) {
            return _activatedTabs.contains(index)
                ? _screens[index]
                : const SizedBox.shrink();
          }),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab,
        onDestinationSelected: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            ref.read(navigationTabProvider.notifier).selectTab(index);
          }
        },
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_outlined),
            selectedIcon: Icon(Icons.flight_takeoff),
            label: 'Flights',
            tooltip: 'Flight Deck & Log Entries',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Logbook',
            tooltip: 'Physical SACAA Ledger Spread',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_special_outlined),
            selectedIcon: Icon(Icons.folder_special),
            label: 'Vault',
            tooltip: 'Endorsement Stamps & Signatures',
          ),
          NavigationDestination(
            icon: Icon(Icons.airplanemode_active_outlined),
            selectedIcon: Icon(Icons.airplanemode_active),
            label: 'Fleet',
            tooltip: 'Aircraft Register & Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            label: 'More',
            tooltip: 'Open Tools, Reports & Settings Drawer',
          ),
        ],
      ),
    );
  }
}
