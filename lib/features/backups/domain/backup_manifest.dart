/// Pure Dart domain model representing individual files within a backup.
class BackupFileEntry {
  final String relativePath;
  final String sha256;
  final int sizeBytes;

  const BackupFileEntry({
    required this.relativePath,
    required this.sha256,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'relativePath': relativePath,
        'sha256': sha256,
        'sizeBytes': sizeBytes,
      };

  factory BackupFileEntry.fromJson(Map<String, dynamic> json) {
    return BackupFileEntry(
      relativePath: json['relativePath'] as String,
      sha256: json['sha256'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupFileEntry &&
          runtimeType == other.runtimeType &&
          relativePath == other.relativePath &&
          sha256 == other.sha256 &&
          sizeBytes == other.sizeBytes;

  @override
  int get hashCode => Object.hash(relativePath, sha256, sizeBytes);
}

/// Pure Dart domain model describing the entire contents of a Spreadlog backup archive.
class BackupManifest {
  static const int currentManifestVersion = 1;

  final int manifestVersion;
  final DateTime createdAt;
  final String appVersion;
  final int schemaVersion;
  final BackupFileEntry databaseEntry;
  final List<BackupFileEntry> documentEntries;
  final int flightCount;
  final int documentCount;
  final int aircraftModelCount;

  const BackupManifest({
    this.manifestVersion = currentManifestVersion,
    required this.createdAt,
    required this.appVersion,
    required this.schemaVersion,
    required this.databaseEntry,
    required this.documentEntries,
    required this.flightCount,
    required this.documentCount,
    required this.aircraftModelCount,
  });

  Map<String, dynamic> toJson() => {
        'manifestVersion': manifestVersion,
        'createdAt': createdAt.toIso8601String(),
        'appVersion': appVersion,
        'schemaVersion': schemaVersion,
        'databaseEntry': databaseEntry.toJson(),
        'documentEntries': documentEntries.map((e) => e.toJson()).toList(),
        'flightCount': flightCount,
        'documentCount': documentCount,
        'aircraftModelCount': aircraftModelCount,
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      manifestVersion: json['manifestVersion'] as int? ?? currentManifestVersion,
      createdAt: DateTime.parse(json['createdAt'] as String),
      appVersion: json['appVersion'] as String? ?? '1.0.0',
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      databaseEntry: BackupFileEntry.fromJson(json['databaseEntry'] as Map<String, dynamic>),
      documentEntries: (json['documentEntries'] as List<dynamic>? ?? [])
          .map((e) => BackupFileEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      flightCount: json['flightCount'] as int? ?? 0,
      documentCount: json['documentCount'] as int? ?? 0,
      aircraftModelCount: json['aircraftModelCount'] as int? ?? 0,
    );
  }

  int get totalSizeBytes =>
      databaseEntry.sizeBytes +
      documentEntries.fold<int>(0, (sum, entry) => sum + entry.sizeBytes);
}
