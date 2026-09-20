import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/endorsement_category.dart';
import '../../domain/endorsement_document.dart';
import '../providers/endorsements_providers.dart';
import '../widgets/endorsement_card.dart';
import '../widgets/endorsement_details_dialog.dart';
import '../widgets/scan_endorsement_dialog.dart';

class EndorsementVaultScreen extends ConsumerStatefulWidget {
  const EndorsementVaultScreen({super.key});

  @override
  ConsumerState<EndorsementVaultScreen> createState() => _EndorsementVaultScreenState();
}

class _EndorsementVaultScreenState extends ConsumerState<EndorsementVaultScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openScanDialog([EndorsementDocument? superseding]) {
    showDialog<void>(
      context: context,
      builder: (ctx) => ScanEndorsementDialog(supersedingDocument: superseding),
    );
  }

  void _openDetailsDialog(EndorsementDocument document) {
    showDialog<void>(
      context: context,
      builder: (ctx) => EndorsementDetailsDialog(
        document: document,
        onSupersede: (docToSupersede) {
          _openScanDialog(docToSupersede);
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asyncDocs = ref.watch(allEndorsementsStreamProvider);
    final endorsements = ref.watch(filteredEndorsementsProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final showSuperseded = ref.watch(showSupersededFilterProvider);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Endorsement Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Scan Endorsement',
            onPressed: () => _openScanDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Superseded toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes, category, or SHA-256...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(endorsementSearchQueryProvider.notifier).setQuery('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      ref.read(endorsementSearchQueryProvider.notifier).setQuery(val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle Show Superseded
                FilterChip(
                  label: const Text('Audit Trail'),
                  tooltip: 'Include superseded / historical documents',
                  avatar: Icon(
                    Icons.history,
                    size: 16,
                    color: showSuperseded ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                  ),
                  selected: showSuperseded,
                  onSelected: (val) {
                    ref.read(showSupersededFilterProvider.notifier).set(val);
                  },
                ),
              ],
            ),
          ),

          // Category Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: selectedCategory == null,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(selectedCategoryFilterProvider.notifier).select(null);
                    }
                  },
                ),
                const SizedBox(width: 6),
                ...EndorsementCategory.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat.label),
                      selected: selectedCategory == cat,
                      onSelected: (selected) {
                        ref.read(selectedCategoryFilterProvider.notifier).select(
                              selected ? cat : null,
                            );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),


          const SizedBox(height: 4),

          // Main Endorsements List
          Expanded(
            child: asyncDocs.isLoading && !asyncDocs.hasValue
                ? const Center(child: CircularProgressIndicator())
                : endorsements.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(

                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_special_outlined,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Endorsements Found',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedCategory != null || _searchController.text.isNotEmpty
                                ? 'No documents match the active category or search query.'
                                : 'Store digital copies of your logbook endorsements, rating certificates, and flight tests with tamper-proof SHA-256 verification.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => _openScanDialog(),
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Add First Endorsement'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: endorsements.length,
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemBuilder: (context, index) {
                      final doc = endorsements[index];
                      return EndorsementCard(
                        document: doc,
                        onTap: () => _openDetailsDialog(doc),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScanDialog(),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Endorsement'),
      ),
    );
  }
}
