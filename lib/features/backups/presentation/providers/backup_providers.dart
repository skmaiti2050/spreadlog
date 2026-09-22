import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../flights/presentation/providers/flights_providers.dart';
import '../../data/backup_archive_service.dart';
import '../../data/backup_service.dart';
import '../../data/backup_settings_repository.dart';
import '../../data/transports/share_backup_transport.dart';
import '../../domain/backup_encryptor.dart';

/// Provider for the secure BackupSettingsRepository.
final backupSettingsRepositoryProvider = Provider<BackupSettingsRepository>((ref) {
  return BackupSettingsRepository();
});

/// Reactive FutureProvider of the user's current backup settings.
final backupSettingsProvider = FutureProvider<BackupSettings>((ref) async {
  final repo = ref.watch(backupSettingsRepositoryProvider);
  return await repo.loadSettings();
});

/// Provider for the pure Dart BackupEncryptor.
final backupEncryptorProvider = Provider<BackupEncryptor>((ref) {
  return BackupEncryptor();
});

/// Provider for the BackupArchiveService.
final backupArchiveServiceProvider = Provider<BackupArchiveService>((ref) {
  return BackupArchiveService();
});

/// Main BackupService provider orchestrating exports and restores.
final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(databaseProvider);
  final encryptor = ref.watch(backupEncryptorProvider);
  final archiveService = ref.watch(backupArchiveServiceProvider);

  return BackupService(
    db: db,
    encryptor: encryptor,
    archiveService: archiveService,
  );
});

/// Provider for OS Share / file export transport.
final shareBackupTransportProvider = Provider<ShareBackupTransport>((ref) {
  return ShareBackupTransport();
});
