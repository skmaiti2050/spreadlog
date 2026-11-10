import '../../domain/backup_exceptions.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../domain/backup_file_name.dart';
import '../providers/backup_providers.dart';
import '../providers/google_auth_providers.dart';

/// Foreground-only web recovery status. Never opens OAuth popups from a timer.
class WebBackupBanner extends ConsumerStatefulWidget {
  final bool enabled;
  final DateTime Function()? clock;
  const WebBackupBanner({super.key, this.enabled = kIsWeb, this.clock});
  @override
  ConsumerState<WebBackupBanner> createState() => _WebBackupBannerState();
}

class _WebBackupBannerState extends ConsumerState<WebBackupBanner>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _busy = false;
  bool _pending = true;
  String _message = 'Checking Google Drive backup status…';
  DateTime? _nextAttempt;
  String? _observedFingerprint;
  String? _observedAccount;
  DateTime? _changedAt;
  bool _active = true;
  String _notice = '';
  String? _authorizedAccount;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_check()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_check());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) unawaited(_check());
  }

  void _show(String text, {bool pending = true}) {
    if (mounted) {
      setState(() {
        _message = text;
        _pending = pending;
      });
    }
  }

  Future<void> _check() async {
    if (_busy || !_active || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _busy = true;
    try {
      final freshness = ref.read(backupFreshnessProvider);
      final repo = ref.read(backupSettingsRepositoryProvider);
      final settings = await repo.loadSettings();
      if (!mounted) return;
      final auth = ref.read(googleAuthServiceProvider);
      final account =
          auth.currentUser?.email ?? settings.googleAccountEmail ?? '';
      final current = await freshness.fingerprint();
      final status = await freshness.status(current, account);
      final now = widget.clock?.call() ?? DateTime.now();
      if (_observedAccount != account) {
        _observedAccount = account;
        _nextAttempt = null;
        _notice = '';
      }
      if (_observedFingerprint != current) {
        _observedFingerprint = current;
        _changedAt = now;
      }
      if (!status.pending) {
        _notice = '';
        _show('Changes backed up to Google Drive.', pending: false);
        return;
      }
      final since = status.lastSuccess == null
          ? 'No verified Drive backup yet.'
          : 'Changes not backed up since ${status.lastSuccess!.toLocal().toString().substring(0, 16)}.';
      _show(_notice.isEmpty ? since : '$since $_notice');
      if (!settings.autoSyncGoogleDrive) return;
      if (_nextAttempt != null && now.isBefore(_nextAttempt!)) return;
      if (now.difference(_changedAt!) < const Duration(seconds: 15)) return;
      _nextAttempt = now.add(const Duration(minutes: 1));
      final passphrase = await repo.getMasterPassphrase();
      if (passphrase == null || passphrase.isEmpty) {
        _notice = 'Set a backup passphrase to enable automatic backups.';
        _show('$since $_notice');
        return;
      }
      final client = await auth.getAuthenticatedClient();
      if (client == null) {
        _notice = 'Reconnect Google Drive to resume automatic backups.';
        _show('$since $_notice');
        return;
      }
      client.close();
      if (!mounted || !_active) return;
      final owner = auth.currentUser?.email;
      _authorizedAccount = owner;
      if (owner == null) return;
      _show('Backing up changes to Google Drive…');
      final backup = await ref
          .read(backupServiceProvider)
          .createTrackedBackup(passphrase: passphrase);
      if (!mounted || auth.currentUser?.email != _authorizedAccount) return;
      final transport = ref.read(googleDriveTransportProvider);
      await transport.dispatchBackup(
        encryptedBytes: backup.bytes,
        suggestedFileName: backupFileName(DateTime.now()),
      );
      await freshness.recordSuccess(backup.fingerprint, owner);
      await repo.recordDriveSyncResult(timestamp: DateTime.now().toUtc());
      if (!mounted) return;
      ref.invalidate(backupSettingsProvider);
      _notice = '';
      final latest = await freshness.fingerprint();
      final pending = latest != backup.fingerprint;
      _show(
        pending
            ? 'New changes are waiting for the next Drive backup.'
            : 'Changes backed up to Google Drive.',
        pending: pending,
      );
    } on BackupAuthorizationException {
      _notice = 'Reconnect Google Drive to resume automatic backups.';
      _show(_notice);
    } catch (_) {
      _notice = 'Check Google Drive connection and retry.';
      _show(
        'Changes are waiting for backup. Check Google Drive connection and retry.',
      );
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.enabled) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            _pending ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(_message)),
          TextButton(
            onPressed: () async {
              if (_notice.contains('Reconnect')) {
                final granted = await ref
                    .read(googleAuthServiceProvider)
                    .requestScopes();
                if (!granted || !mounted) return;
              } else {
                await Navigator.of(context).pushNamed(AppRouter.backupsRoute);
              }
              _nextAttempt = null;
              _notice = '';
              await _check();
            },
            child: Text(
              _notice.contains('Reconnect') ? 'Reconnect Drive' : 'Backups',
            ),
          ),
        ],
      ),
    );
  }
}
