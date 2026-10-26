import 'package:flutter/foundation.dart';

/// How the database is persisted on this platform, as reported when it opens.
class StorageStatus {
  /// Storage backend name, e.g. drift's `sharedIndexedDb`, or `native`.
  final String implementation;

  /// Browser features drift found missing when choosing [implementation].
  final List<String> missingFeatures;

  /// False when nothing survives a reload: drift fell back to memory because
  /// no persistent browser storage was usable.
  final bool isPersistent;

  const StorageStatus({
    required this.implementation,
    this.missingFeatures = const [],
    required this.isPersistent,
  });

  @override
  String toString() =>
      'StorageStatus($implementation, persistent: $isPersistent, '
      'missing: $missingFeatures)';
}

/// Set once the database connection opens; null until then.
final ValueNotifier<StorageStatus?> storageStatus = ValueNotifier(null);
