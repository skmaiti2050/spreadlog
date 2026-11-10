import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/app_database.dart';
import '../../endorsements/domain/document_hasher.dart';
import '../../profile/data/pilot_profile_repository.dart';

/// Fingerprints content rather than timestamps, so deletions and child-table
/// changes are detected too. A completed upload acknowledges only its snapshot.
class BackupFreshnessService {
  final AppDatabase db;
  final SharedPreferencesAsync preferences;
  BackupFreshnessService(this.db, {SharedPreferencesAsync? preferences})
    : preferences = preferences ?? SharedPreferencesAsync();

  static const _fingerprintKey = 'drive_success_fingerprint';
  static const _successKey = 'drive_success_at';
  static const _accountKey = 'drive_success_account';

  Future<String> fingerprint() async {
    final content = <String, Object?>{};
    // All names come from the local schema, never from user input.
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    await db.transaction(() async {
      for (final table in tables) {
        final name = table.read<String>('name');
        final escaped = name.replaceAll('"', '""');
        final rows = await db.customSelect('SELECT * FROM "$escaped"').get();
        final canonical = rows.map((row) => jsonEncode(row.data)).toList()
          ..sort();
        content[name] = canonical;
      }
    });
    content['pilotProfile'] =
        (await const PilotProfileRepository().getProfile()).toJson();
    return DocumentHasher().computeSha256(
      Uint8List.fromList(utf8.encode(jsonEncode(content))),
    );
  }

  Future<({bool pending, DateTime? lastSuccess})> status(
    String currentFingerprint,
    String account,
  ) async {
    final saved = await preferences.getString(_fingerprintKey);
    final owner = await preferences.getString(_accountKey);
    final date = await preferences.getString(_successKey);
    final sameAccount = owner == account.toLowerCase();
    return (
      pending: !sameAccount || saved != currentFingerprint,
      lastSuccess: sameAccount && date != null ? DateTime.tryParse(date) : null,
    );
  }

  Future<void> recordSuccess(String snapshotFingerprint, String account) async {
    await preferences.setString(_fingerprintKey, snapshotFingerprint);
    await preferences.setString(_accountKey, account.toLowerCase());
    await preferences.setString(
      _successKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
