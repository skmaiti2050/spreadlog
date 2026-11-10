import 'dart:typed_data';

import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/backups/data/backup_freshness_service.dart';
import 'package:aviation_logbook/features/backups/data/backup_service.dart';
import 'package:aviation_logbook/features/backups/data/backup_settings_repository.dart';
import 'package:aviation_logbook/features/backups/data/google_auth_service.dart';
import 'package:aviation_logbook/features/backups/data/transports/google_drive_backup_transport.dart';
import 'package:aviation_logbook/features/backups/presentation/providers/backup_providers.dart';
import 'package:aviation_logbook/features/backups/presentation/providers/google_auth_providers.dart';
import 'package:aviation_logbook/features/backups/presentation/widgets/web_backup_banner.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_freshness_service_test.dart' show MemoryPreferences;

class _Client implements AuthClient {
  @override
  void close() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements GoogleAuthService {
  bool authorized = false;
  int checks = 0;
  int interactiveRequests = 0;
  @override
  Future<bool> requestScopes() async {
    interactiveRequests++;
    authorized = true;
    return true;
  }

  @override
  GoogleUser? get currentUser =>
      const GoogleUser(id: 'pilot', email: 'pilot@example.com');
  @override
  Future<AuthClient?> getAuthenticatedClient() async {
    checks++;
    return authorized ? _Client() : null;
  }

  // Unexpected interactive OAuth calls fail the test.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings implements BackupSettingsRepository {
  @override
  Future<BackupSettings> loadSettings() async => const BackupSettings(
    hasMasterPassphrase: true,
    autoSyncGoogleDrive: true,
    googleAccountEmail: 'pilot@example.com',
  );
  @override
  Future<String?> getMasterPassphrase() async => 'passphrase';
  @override
  Future<void> recordDriveSyncResult({
    required DateTime timestamp,
    String? error,
  }) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Backup implements BackupService {
  final BackupFreshnessService freshness;
  _Backup(this.freshness);
  @override
  Future<({Uint8List bytes, String fingerprint})> createTrackedBackup({
    required String passphrase,
  }) async => (
    bytes: Uint8List.fromList([1]),
    fingerprint: await freshness.fingerprint(),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Drive implements GoogleDriveBackupTransport {
  int uploads = 0;
  Future<void> Function()? duringUpload;
  @override
  Future<void> dispatchBackup({
    required Uint8List encryptedBytes,
    required String suggestedFileName,
    String? recipientEmail,
  }) async {
    uploads++;
    await duringUpload?.call();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> flush(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets(
    'expired authorization pauses, reconnect resumes, upload-time edits stay pending',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase(NativeDatabase.memory());
      final freshness = BackupFreshnessService(
        db,
        preferences: MemoryPreferences(),
      );
      final auth = _Auth();
      final drive = _Drive();
      var now = DateTime(2026);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupFreshnessProvider.overrideWithValue(freshness),
            backupSettingsRepositoryProvider.overrideWithValue(_Settings()),
            googleAuthServiceProvider.overrideWithValue(auth),
            backupServiceProvider.overrideWithValue(_Backup(freshness)),
            googleDriveTransportProvider.overrideWithValue(drive),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: WebBackupBanner(enabled: true, clock: () => now),
            ),
          ),
        ),
      );
      await flush(tester);
      now = now.add(const Duration(seconds: 16));
      await tester.pump(const Duration(seconds: 15));
      await flush(tester);
      expect(find.textContaining('Reconnect Google Drive'), findsOneWidget);
      expect(drive.uploads, 0);
      final checks = auth.checks;
      now = now.add(const Duration(seconds: 15));
      await tester.pump(const Duration(seconds: 15));
      await flush(tester);
      expect(auth.checks, checks);
      expect(find.textContaining('Reconnect Google Drive'), findsOneWidget);
      expect(auth.interactiveRequests, 0);
      drive.duringUpload = () =>
          db.flightsDao.ensureAircraftModelExists(modelId: 'LATE');
      await tester.tap(find.text('Reconnect Drive'));
      await flush(tester);
      expect(auth.interactiveRequests, 1);
      expect(drive.uploads, 1);
      expect(find.textContaining('New changes are waiting'), findsOneWidget);
      expect(
        (await tester.runAsync(
          () async => freshness.status(
            await freshness.fingerprint(),
            'pilot@example.com',
          ),
        ))!.pending,
        isTrue,
      );
      drive.duringUpload = null;
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 15));
      await flush(tester);
      now = now.add(const Duration(seconds: 16));
      await tester.pump(const Duration(seconds: 15));
      await flush(tester);
      expect(drive.uploads, 2);
      expect(find.text('Changes backed up to Google Drive.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(db.close);
      await tester.pump(const Duration(minutes: 2));
      expect(tester.takeException(), isNull);
    },
  );
}
