import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/backups/presentation/screens/backup_restore_screen.dart';
import '../../features/flights/presentation/providers/flights_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/profile/presentation/widgets/edit_profile_dialog.dart';
import '../../features/reports/presentation/pdf_preview_screen.dart';
import '../../features/reports/presentation/summary_slip_preview_screen.dart';
import '../theme/aviation_theme.dart';
import '../utils/time_utils.dart';

/// Clean, cockpit-themed sliding side drawer accessible across all primary screens.
class AviationAppDrawer extends ConsumerWidget {
  final ValueChanged<int>? onDestinationSelected;

  const AviationAppDrawer({super.key, this.onDestinationSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(pilotProfileProvider);
    final totals = ref.watch(grandTotalsProvider);
    final activeTheme = ref.watch(aviationThemeProvider);

    return Drawer(
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Pilot Profile & Aviation Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 20,
                16,
                16,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          Icons.flight,
                          color: theme.colorScheme.onPrimary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.pilotName.isEmpty
                                  ? 'Profile not set up'
                                  : profile.pilotName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              profile.licenceNumber.isEmpty
                                  ? 'Licence: Pending'
                                  : '${profile.licenceNumber} • SACAA',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL TIME',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${TimeUtils.formatMinutesToHhMm(totals.totalFlightTimeMinutes)} (${TimeUtils.formatMinutesToDecimal(totals.totalFlightTimeMinutes)} hrs)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // REPORTS & COMPLIANCE
                  _buildSectionHeader(context, 'REPORTS & COMPLIANCE'),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.picture_as_pdf,
                    label: 'Export Logbook PDF',
                    subtitle: 'SACAA Multi-Page Archival PDF',
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      final pages = ref.read(ledgerPagesProvider);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PdfPreviewScreen(
                            pages: pages,
                            pilotName: profile.pilotName,
                            licenceNumber: profile.licenceNumber,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.receipt_long,
                    label: 'Career Summary Slip',
                    subtitle: 'Cumulative Aircraft Breakdown',
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      final typeSummaries = ref.read(
                        aircraftTypeSummariesProvider,
                      );
                      final grandTotals = ref.read(grandTotalsProvider);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SummarySlipPreviewScreen(
                            typeSummaries: typeSummaries,
                            grandTotals: grandTotals,
                          ),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 24),

                  // TOOLS & CONFIGURATION
                  _buildSectionHeader(context, 'TOOLS & SETTINGS'),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.backup_outlined,
                    label: 'Backup & Restore',
                    subtitle: 'AES-256 Encrypted Archives',
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BackupRestoreScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.account_circle_outlined,
                    label: 'Pilot Profile',
                    subtitle: 'Name, Licence & Regulator',
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      EditProfileDialog.show(context);
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: activeTheme.icon,
                    label: 'Cockpit Theme',
                    subtitle: activeTheme.displayName,
                    isSelected: false,
                    trailing: const Icon(Icons.swap_horiz, size: 20),
                    onTap: () {
                      ref.read(aviationThemeProvider.notifier).cycleNext();
                    },
                  ),
                ],
              ),
            ),

            // Drawer Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spreadlog Aviation',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '1.0.4 (5)\n${const String.fromEnvironment('BUILD_COMMIT', defaultValue: 'local')}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.35,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
