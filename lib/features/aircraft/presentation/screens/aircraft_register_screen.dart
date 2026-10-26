import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../endorsements/presentation/providers/endorsements_providers.dart';
import '../../../endorsements/presentation/widgets/endorsement_details_dialog.dart';
import '../../domain/aircraft_model.dart';
import '../providers/aircraft_providers.dart';
import '../widgets/endorse_aircraft_dialog.dart';

enum AircraftRegisterFilter { all, singleEngine, multiEngine, endorsedOnly }

class AircraftRegisterScreen extends ConsumerStatefulWidget {
  const AircraftRegisterScreen({super.key});

  @override
  ConsumerState<AircraftRegisterScreen> createState() =>
      _AircraftRegisterScreenState();
}

class _AircraftRegisterScreenState
    extends ConsumerState<AircraftRegisterScreen> {
  AircraftRegisterFilter _filter = AircraftRegisterFilter.all;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddEditDialog([EndorsedAircraftEntry? entry]) {
    showDialog<bool>(
      context: context,
      builder: (_) => EndorseAircraftDialog(
        initialModel: entry?.model,
        initialEndorsement: entry?.endorsement,
      ),
    );
  }

  Future<void> _viewVaultDocument(String docId) async {
    final repo = ref.read(endorsementsRepositoryProvider);
    final doc = await repo.getEndorsementById(docId);
    if (!mounted) return;

    if (doc != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => EndorsementDetailsDialog(document: doc),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Linked vault document not found.')),
      );
    }
  }

  Future<void> _confirmDelete(EndorsedAircraftEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Aircraft Model'),
        content: Text(
          'Are you sure you want to remove ${entry.model.displayName} (${entry.model.id}) from your register? Any associated endorsement sign-offs will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(aircraftRepositoryProvider);
      await repo.deleteModel(entry.model.id);
      if (entry.endorsement != null) {
        await repo.deleteEndorsement(entry.endorsement!.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed ${entry.model.id} from register')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allEntries = ref.watch(endorsedAircraftListProvider);

    final seCount = allEntries
        .where((e) => e.model.aircraftClass == AircraftClass.singleEngine)
        .length;
    final meCount = allEntries
        .where((e) => e.model.aircraftClass == AircraftClass.multiEngine)
        .length;
    final endorsedCount = allEntries.where((e) => e.isEndorsed).length;

    final filteredEntries = allEntries.where((entry) {
      if (_filter == AircraftRegisterFilter.singleEngine &&
          entry.model.aircraftClass != AircraftClass.singleEngine) {
        return false;
      }
      if (_filter == AircraftRegisterFilter.multiEngine &&
          entry.model.aircraftClass != AircraftClass.multiEngine) {
        return false;
      }
      if (_filter == AircraftRegisterFilter.endorsedOnly && !entry.isEndorsed) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchId = entry.model.id.toLowerCase().contains(query);
        final matchName = entry.model.displayName.toLowerCase().contains(query);
        if (!matchId && !matchName) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Aircraft Model Register')),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by model code or manufacturer...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All (${allEntries.length})',
                        filter: AircraftRegisterFilter.all,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Single-Engine ($seCount)',
                        filter: AircraftRegisterFilter.singleEngine,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Multi-Engine ($meCount)',
                        filter: AircraftRegisterFilter.multiEngine,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Endorsed Only ($endorsedCount)',
                        filter: AircraftRegisterFilter.endorsedOnly,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List of Aircraft
          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.airplanemode_inactive,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No aircraft models found.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return _buildAircraftCard(context, theme, entry);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'aircraft_register_fab',
        onPressed: () => _openAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Aircraft'),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required AircraftRegisterFilter filter,
  }) {
    final isSelected = _filter == filter;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = filter),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildAircraftCard(
    BuildContext context,
    ThemeData theme,
    EndorsedAircraftEntry entry,
  ) {
    final m = entry.model;
    final e = entry.endorsement;
    final isMe = m.aircraftClass == AircraftClass.multiEngine;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: entry.isEndorsed
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Code badge, display name, class tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.indigo.withValues(alpha: 0.15)
                        : Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    m.id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isMe ? Colors.indigo : Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? theme.colorScheme.errorContainer.withValues(
                            alpha: 0.4,
                          )
                        : theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isMe ? 'MULTI-ENGINE' : 'SINGLE-ENGINE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isMe
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Endorsement Status Pill
            if (entry.isEndorsed) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Endorsed: ${TimeUtils.formatDate(e!.pilotDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    if (e.sourceDocumentId != null)
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Vault Scan',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () =>
                            _viewVaultDocument(e.sourceDocumentId!),
                      ),
                  ],
                ),
              ),
              if (e.instructorDate != null || e.instructorName != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Instructor: ${e.instructorName ?? "Authorized Instructor"}'
                  '${e.instructorLicence != null ? " (Lic #${e.instructorLicence})" : ""}'
                  '${e.instructorDate != null ? " • Check: ${TimeUtils.formatDate(e.instructorDate!)}" : ""}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (e.notes != null && e.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Notes: ${e.notes}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Not endorsed yet',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Remove',
                  color: Colors.red.withValues(alpha: 0.7),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDelete(entry),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  onPressed: () => _openAddEditDialog(entry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
