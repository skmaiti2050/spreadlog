import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/endorsements_dao.dart';
import '../../../flights/presentation/providers/flights_providers.dart';
import '../../data/endorsements_repository.dart';
import '../../data/scanner/document_scanner_adapter.dart';
import '../../domain/endorsement_category.dart';
import '../../domain/endorsement_document.dart';
import '../../domain/scanner/document_scanner_port.dart';

final endorsementsDaoProvider = Provider<EndorsementsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.endorsementsDao;
});

final endorsementsRepositoryProvider = Provider<EndorsementsRepository>((ref) {
  final dao = ref.watch(endorsementsDaoProvider);
  return EndorsementsRepository(dao: dao);
});

final documentScannerPortProvider = Provider<DocumentScannerPort>((ref) {
  return const DocumentScannerAdapter();
});

class ShowSupersededNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool val) => state = val;
}

/// Whether to include superseded (historical/replaced) endorsement records.
final showSupersededFilterProvider =
    NotifierProvider<ShowSupersededNotifier, bool>(ShowSupersededNotifier.new);

class SelectedCategoryNotifier extends Notifier<EndorsementCategory?> {
  @override
  EndorsementCategory? build() => null;

  void select(EndorsementCategory? cat) => state = cat;
}

/// Currently selected category filter (null = all categories).
final selectedCategoryFilterProvider =
    NotifierProvider<SelectedCategoryNotifier, EndorsementCategory?>(SelectedCategoryNotifier.new);

class EndorsementSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

/// Search filter text.
final endorsementSearchQueryProvider =
    NotifierProvider<EndorsementSearchQueryNotifier, String>(EndorsementSearchQueryNotifier.new);

/// Reactive stream of all endorsement documents.
final allEndorsementsStreamProvider = StreamProvider<List<EndorsementDocument>>((ref) {
  final repository = ref.watch(endorsementsRepositoryProvider);
  return repository.watchEndorsements(includeSuperseded: true);
});

/// Filtered list of endorsements adhering to selected category, search query, and supersede status.
/// Evaluated synchronously in memory so toggling filters never flashes or re-queries SQLite.
final filteredEndorsementsProvider = Provider<List<EndorsementDocument>>((ref) {
  final asyncDocs = ref.watch(allEndorsementsStreamProvider);
  final showSuperseded = ref.watch(showSupersededFilterProvider);
  final selectedCategory = ref.watch(selectedCategoryFilterProvider);
  final query = ref.watch(endorsementSearchQueryProvider).trim().toLowerCase();

  final allDocs = asyncDocs.value ?? [];

  return allDocs.where((doc) {
    if (!showSuperseded && doc.isSuperseded) {
      return false;
    }
    if (selectedCategory != null && doc.category != selectedCategory) {
      return false;
    }
    if (query.isNotEmpty) {
      final matchesNotes = doc.notes?.toLowerCase().contains(query) ?? false;
      final matchesCat = doc.category.label.toLowerCase().contains(query);
      final matchesSha = doc.sha256.toLowerCase().contains(query);
      if (!matchesNotes && !matchesCat && !matchesSha) {
        return false;
      }
    }
    return true;
  }).toList();
});

