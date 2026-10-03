import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../flights/presentation/providers/flights_providers.dart';
import '../../data/backup_service.dart';
import '../../data/backup_settings_repository.dart';
import '../../data/backup_workmanager_service.dart';
import '../../data/transports/google_drive_backup_transport.dart';
import '../../data/transports/smtp_backup_transport.dart';
import '../../domain/backup_exceptions.dart';
import '../providers/backup_providers.dart';
import '../providers/google_auth_providers.dart';
import '../widgets/google_sign_in_button.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  static const Color _accentGreen = Color(0xFF4CAF50);
  static const Color _accentWarning = Color(0xFFFFA726);
  static const Color _accentError = Color(0xFFEF5350);
  static const Color _accentBlue = Color(0xFF42A5F5);
  static const Color _accentPurple = Color(0xFFAB47BC);

  int _selectedSegment = 0; // 0: Local/Offline, 1: Google Drive, 2: Email
  bool _isLoading = false;
  String? _loadingMessage;

  List<GoogleDriveBackupItem>? _driveBackups;
  bool _isLoadingDriveBackups = false;

  @override
  void initState() {
    super.initState();
    // Silently attempt Google sign-in on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trySilentGoogleSignIn();
    });
  }

  Future<void> _trySilentGoogleSignIn() async {
    final authService = ref.read(googleAuthServiceProvider);
    final user = await authService.signInSilently();
    if (user != null && mounted) {
      unawaited(_loadDriveBackups());
    }
  }

  Future<void> _loadDriveBackups() async {
    final authService = ref.read(googleAuthServiceProvider);
    if (!authService.isSignedIn) return;

    if (kIsWeb) {
      final hasAccess = await authService.canAccessScopes();
      if (!hasAccess) {
        if (mounted) {
          setState(() {
            _driveBackups = null;
            _isLoadingDriveBackups = false;
          });
        }
        return;
      }
    }

    setState(() => _isLoadingDriveBackups = true);
    try {
      final driveTransport = ref.read(googleDriveTransportProvider);
      final backups = await driveTransport.listBackups();
      if (mounted) {
        setState(() {
          _driveBackups = backups;
          _isLoadingDriveBackups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDriveBackups = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(backupSettingsProvider);
    final flightsAsync = ref.watch(flightsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Cloud Sync Hub'),
      ),
      body: Stack(
        children: [
          settingsAsync.when(
            data: (settings) => _buildContent(context, settings, flightsAsync.value?.length ?? 0),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading settings: $err')),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage ?? 'Processing...',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BackupSettings settings, int currentFlightCount) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top Master Passphrase Status Card
        _buildMasterPassphraseCard(context, settings),
        const SizedBox(height: 16),

        // 3-Option Segment Selector
        Center(
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 0,
                icon: Icon(Icons.sd_storage_outlined),
                label: Text('Local / Offline'),
              ),
              ButtonSegment<int>(
                value: 1,
                icon: Icon(Icons.cloud_sync_outlined),
                label: Text('Google Drive'),
              ),
              ButtonSegment<int>(
                value: 2,
                icon: Icon(Icons.email_outlined),
                label: Text('Email'),
              ),
            ],
            selected: {_selectedSegment},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _selectedSegment = newSelection.first;
              });
              if (_selectedSegment == 1 && _driveBackups == null) {
                _loadDriveBackups();
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // Segment Content
        if (_selectedSegment == 0) ...[
          _buildExportCard(context, settings, currentFlightCount),
          const SizedBox(height: 16),
          _buildRestoreCard(context, settings),
        ] else if (_selectedSegment == 1) ...[
          _buildGoogleDriveSyncCard(context, settings),
        ] else if (_selectedSegment == 2) ...[
          _buildEmailDispatchCard(context, settings),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  // ==========================================
  // SECTION: MASTER PASSPHRASE
  // ==========================================
  Widget _buildMasterPassphraseCard(BuildContext context, BackupSettings settings) {
    final isConfigured = settings.hasMasterPassphrase;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: isConfigured ? _accentGreen : _accentWarning,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Master Encryption Passphrase',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isConfigured
                            ? 'Passphrase saved in hardware-backed secure storage.'
                            : 'No passphrase set. All backups are encrypted with your key.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isConfigured ? _accentGreen : _accentWarning,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: Icon(isConfigured ? Icons.edit : Icons.key, size: 16),
                  label: Text(isConfigured ? 'Change' : 'Set Key'),
                  onPressed: () => _promptConfigurePassphrase(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 1: OFFLINE / LOCAL BACKUP & RESTORE
  // ==========================================
  Widget _buildExportCard(BuildContext context, BackupSettings settings, int flightCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.upload_file, color: _accentBlue, size: 26),
                SizedBox(width: 12),
                Text(
                  'Export Local Archive (.spbackup)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Packages your SQLite database and scanned endorsement stamps into a tamper-evident, '
              'AES-256 encrypted file. Works 100% offline with zero internet required.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  avatar: const Icon(Icons.flight, size: 16),
                  label: Text('$flightCount Flights'),
                ),
                const Chip(
                  avatar: Icon(Icons.lock, size: 16),
                  label: Text('AES-256-GCM'),
                ),
                const Chip(
                  avatar: Icon(Icons.verified_user, size: 16),
                  label: Text('SHA-256 Verified'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Export / Share .spbackup File'),
                onPressed: () => _handleExport(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreCard(BuildContext context, BackupSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings_backup_restore, color: _accentPurple, size: 26),
                SizedBox(width: 12),
                Text(
                  'Restore from Local File',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an encrypted .spbackup file from your device storage or files app. '
              'Every file checksum is verified before applying changes with rollback safety.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Select & Restore .spbackup File'),
                onPressed: () => _handlePickAndRestore(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 2: GOOGLE DRIVE CLOUD SYNC
  // ==========================================
  Widget _buildGoogleDriveSyncCard(BuildContext context, BackupSettings settings) {
    final authService = ref.watch(googleAuthServiceProvider);
    final userAsync = ref.watch(googleUserStreamProvider);
    final user = userAsync.value ?? authService.currentUser;
    final isSignedIn = user != null;

    return Column(
      children: [
        // Google Account Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isSignedIn ? Colors.blue.shade800 : Colors.grey.shade800,
                      child: Icon(
                        isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSignedIn ? (user.displayName ?? 'Google Account') : 'Google Cloud Sync',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isSignedIn ? user.email : 'Not connected to Google Drive',
                            style: TextStyle(
                              fontSize: 13,
                              color: isSignedIn ? _accentGreen : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSignedIn)
                      TextButton.icon(
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Sign Out'),
                        onPressed: _handleGoogleSignOut,
                      )
                    else
                      buildGoogleSignInButton(
                        onPressed: _handleGoogleSignIn,
                      ),
                  ],
                ),
                if (!isSignedIn) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Connect your Google Account to automatically store and sync your AES-256 encrypted '
                    'flight logbook in Google Drive. Zero passwords stored, and only Spreadlog files are accessed.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
                if (isSignedIn && kIsWeb) ...[
                  const SizedBox(height: 12),
                  FutureBuilder<bool>(
                    future: authService.canAccessScopes(),
                    builder: (context, snapshot) {
                      final hasScopes = snapshot.data ?? false;
                      if (!hasScopes) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade900.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: Colors.amber, size: 22),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Google Drive permission required to sync files.',
                                  style: TextStyle(fontSize: 12, color: Colors.white),
                                ),
                              ),
                              FilledButton.tonal(
                                onPressed: () async {
                                  final ok = await authService.requestScopes();
                                  if (ok && mounted) {
                                    setState(() {});
                                    await _loadDriveBackups();
                                  }
                                },
                                child: const Text('Authorize'),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (isSignedIn) ...[
          // Actions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cloud Sync Controls',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Automatic Background Sync'),
                    subtitle: const Text(
                      'Silently upload encrypted backups to Google Drive in the background via WorkManager.',
                    ),
                    value: settings.autoSyncGoogleDrive,
                    onChanged: (val) => _toggleAutoSyncDrive(settings, val),
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Backup to Google Drive Now'),
                      onPressed: _handleBackupToDrive,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cloud Backups List Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Backups in Google Drive',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh list',
                        onPressed: _loadDriveBackups,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingDriveBackups)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_driveBackups == null || _driveBackups!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No cloud backups found in Google Drive.\nTap "Backup to Google Drive Now" to upload one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _driveBackups!.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _driveBackups![index];
                        final dateStr = item.createdTime != null
                            ? item.createdTime!.toLocal().toString().substring(0, 16)
                            : 'Unknown date';
                        final sizeKb = (item.sizeBytes / 1024).toStringAsFixed(1);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.cloud_done, color: _accentGreen),
                          title: Text(item.name, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('$dateStr • $sizeKb KB'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore, color: _accentBlue),
                                tooltip: 'Restore from this backup',
                                onPressed: () => _handleRestoreFromDrive(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: _accentError),
                                tooltip: 'Delete cloud backup',
                                onPressed: () => _handleDeleteFromDrive(item),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // SECTION 3: EMAIL BACKUP DISPATCH
  // ==========================================
  Widget _buildEmailDispatchCard(BuildContext context, BackupSettings settings) {
    final authService = ref.watch(googleAuthServiceProvider);
    final userAsync = ref.watch(googleUserStreamProvider);
    final user = userAsync.value ?? authService.currentUser;
    final isSignedIn = user != null;

    return Column(
      children: [
        // 1-Tap Google Email Dispatch
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mark_email_read, color: _accentBlue, size: 26),
                    SizedBox(width: 12),
                    Text(
                      'Email Backup to Myself (Google)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sends the AES-256 encrypted logbook backup directly to your Gmail inbox via the Google REST API. '
                  'Zero password configuration or SMTP ports required.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                if (isSignedIn) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text('Send Encrypted Backup to ${user.email}'),
                      onPressed: () => _handleSendGmailBackup(user.email),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google to Email Yourself'),
                      onPressed: _handleGoogleSignIn,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Custom SMTP Fallback Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: _accentWarning, size: 26),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Custom SMTP Server (Advanced)',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Switch(
                      value: settings.autoBackupEnabled,
                      onChanged: (enabled) => _toggleAutoBackup(settings, enabled),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'For pilots using custom email domains, Outlook, or private mail servers. '
                  'Requires custom SMTP host, port, TLS, and mailbox credentials.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                if (settings.lastBackupDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last Email: ${settings.lastBackupDate!.toLocal().toString().substring(0, 16)} '
                    '(${settings.lastBackupStatus ?? "OK"})',
                    style: const TextStyle(fontSize: 12, color: _accentGreen),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text('Configure SMTP'),
                        onPressed: () => _promptConfigureSmtp(settings),
                      ),
                    ),
                    if (settings.smtpHost != null && settings.smtpHost!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.send),
                        label: const Text('Send Test'),
                        onPressed: () => _sendTestEmailBackup(settings),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SHARED ACTIONS & HANDLERS
  // ==========================================

  Future<void> _handleGoogleSignIn() async {
    final authService = ref.read(googleAuthServiceProvider);
    try {
      final account = await authService.signIn();
      final resolvedUser = account ?? authService.currentUser;
      if (resolvedUser != null && mounted) {
        final repo = ref.read(backupSettingsRepositoryProvider);
        final settings = await repo.loadSettings();
        await repo.updateSettings(settings.copyWith(googleAccountEmail: resolvedUser.email));
        ref.invalidate(backupSettingsProvider);
        await _loadDriveBackups();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to Google as ${resolvedUser.email}'),
              backgroundColor: _accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      final resolvedUser = authService.currentUser;
      if (resolvedUser != null && mounted) {
        // User is actually signed in (e.g. through One Tap or parallel selection)
        final repo = ref.read(backupSettingsRepositoryProvider);
        final settings = await repo.loadSettings();
        await repo.updateSettings(settings.copyWith(googleAccountEmail: resolvedUser.email));
        ref.invalidate(backupSettingsProvider);
        await _loadDriveBackups();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: _accentError,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignOut() async {
    final authService = ref.read(googleAuthServiceProvider);
    await authService.signOut();
    final repo = ref.read(backupSettingsRepositoryProvider);
    final settings = await repo.loadSettings();
    await repo.updateSettings(settings.copyWith(googleAccountEmail: null));
    ref.invalidate(backupSettingsProvider);
    setState(() {
      _driveBackups = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out of Google.')),
      );
    }
  }

  Future<void> _handleBackupToDrive() async {
    final authService = ref.read(googleAuthServiceProvider);
    if (kIsWeb) {
      final hasAccess = await authService.canAccessScopes();
      if (!hasAccess) {
        final granted = await authService.requestScopes();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Google Drive permission is required to upload backups.'),
                backgroundColor: _accentWarning,
              ),
            );
          }
          return;
        }
      }
    }

    final repo = ref.read(backupSettingsRepositoryProvider);
    String? passphrase = await repo.getMasterPassphrase();

    if (!mounted) return;

    if (passphrase == null || passphrase.isEmpty) {
      passphrase = await _promptEnterPassphraseDialog(
        title: 'Encryption Passphrase Required',
        message: 'Enter your master passphrase to encrypt this cloud backup.',
      );
    }

    if (passphrase == null || passphrase.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Creating encrypted backup & uploading to Google Drive...';
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final encryptedBytes = await backupService.createEncryptedBackup(passphrase: passphrase);

      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = 'spreadlog_backup_$nowStr.spbackup';

      final driveTransport = ref.read(googleDriveTransportProvider);
      await driveTransport.dispatchBackup(
        encryptedBytes: encryptedBytes,
        suggestedFileName: fileName,
      );

      await repo.recordBackupResult(timestamp: DateTime.now().toUtc(), status: 'Google Drive Sync OK');
      ref.invalidate(backupSettingsProvider);
      await _loadDriveBackups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup saved to Google Drive ($fileName • ${(encryptedBytes.length / 1024).toStringAsFixed(1)} KB)',
            ),
            backgroundColor: _accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Drive backup failed: $e'),
            backgroundColor: _accentError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRestoreFromDrive(GoogleDriveBackupItem item) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Downloading ${item.name} from Google Drive...';
    });

    try {
      final driveTransport = ref.read(googleDriveTransportProvider);
      final fileBytes = await driveTransport.downloadBackup(item.id);

      if (!mounted) return;
      setState(() => _isLoading = false);

      await _performRestore(fileBytes, originName: item.name);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download from Google Drive: $e'),
            backgroundColor: _accentError,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteFromDrive(GoogleDriveBackupItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cloud Backup?'),
        content: Text('Are you sure you want to delete ${item.name} from Google Drive?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accentError),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final driveTransport = ref.read(googleDriveTransportProvider);
      await driveTransport.deleteBackup(item.id);
      await _loadDriveBackups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup removed from Google Drive.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: _accentError),
        );
      }
    }
  }

  Future<void> _handleSendGmailBackup(String recipientEmail) async {
    final authService = ref.read(googleAuthServiceProvider);
    if (kIsWeb) {
      final hasAccess = await authService.canAccessScopes();
      if (!hasAccess) {
        final granted = await authService.requestScopes();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gmail permission is required to send backups.'),
                backgroundColor: _accentWarning,
              ),
            );
          }
          return;
        }
      }
    }

    final repo = ref.read(backupSettingsRepositoryProvider);
    String? passphrase = await repo.getMasterPassphrase();

    if (!mounted) return;

    if (passphrase == null || passphrase.isEmpty) {
      passphrase = await _promptEnterPassphraseDialog(
        title: 'Encryption Passphrase Required',
        message: 'Enter your master passphrase to encrypt this email backup.',
      );
    }

    if (passphrase == null || passphrase.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Sending encrypted backup to $recipientEmail via Gmail API...';
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final encryptedBytes = await backupService.createEncryptedBackup(passphrase: passphrase);

      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = 'spreadlog_backup_$nowStr.spbackup';

      final gmailTransport = ref.read(gmailTransportProvider);
      await gmailTransport.dispatchBackup(
        encryptedBytes: encryptedBytes,
        suggestedFileName: fileName,
        recipientEmail: recipientEmail,
      );

      await repo.recordBackupResult(timestamp: DateTime.now().toUtc(), status: 'Gmail Dispatch OK');
      ref.invalidate(backupSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Encrypted backup successfully sent to $recipientEmail!'),
            backgroundColor: _accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gmail dispatch failed: $e'),
            backgroundColor: _accentError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleExport() async {
    final repo = ref.read(backupSettingsRepositoryProvider);
    String? passphrase = await repo.getMasterPassphrase();

    if (!mounted) return;

    if (passphrase == null || passphrase.isEmpty) {
      passphrase = await _promptEnterPassphraseDialog(
        title: 'Encryption Passphrase Required',
        message: 'Enter a master passphrase to encrypt this backup archive.',
      );
    }

    if (passphrase == null || passphrase.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Creating encrypted backup archive...';
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final encryptedBytes = await backupService.createEncryptedBackup(passphrase: passphrase);

      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = 'spreadlog_backup_$nowStr.spbackup';

      if (!mounted) return;

      setState(() {
        _loadingMessage = 'Exporting via OS Share...';
      });

      final transport = ref.read(shareBackupTransportProvider);
      await transport.dispatchBackup(
        encryptedBytes: encryptedBytes,
        suggestedFileName: fileName,
      );

      await repo.recordBackupResult(timestamp: DateTime.now().toUtc(), status: 'Exported');
      ref.invalidate(backupSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup exported successfully (${(encryptedBytes.length / 1024).toStringAsFixed(1)} KB)',
            ),
            backgroundColor: _accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: _accentError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePickAndRestore() async {
    final pickedFiles = await FilePicker.pickFiles(type: FileType.any);
    if (pickedFiles.isEmpty) return;

    final pickedFile = pickedFiles.first;
    final fileBytes = await pickedFile.readAsBytes();

    await _performRestore(fileBytes, originName: pickedFile.name);
  }

  Future<void> _performRestore(Uint8List fileBytes, {String originName = 'archive'}) async {
    if (!mounted) return;

    final passphrase = await _promptEnterPassphraseDialog(
      title: 'Enter Backup Passphrase',
      message: 'Enter the passphrase used to encrypt this archive.',
    );

    if (passphrase == null || passphrase.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Inspecting archive & verifying SHA-256 hashes...';
    });

    final backupService = ref.read(backupServiceProvider);
    BackupInspectionResult inspection;

    try {
      inspection = await backupService.inspectBackup(
        backupBytes: fileBytes,
        passphrase: passphrase,
      );
    } on InvalidPassphraseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect passphrase. Decryption failed.'),
            backgroundColor: _accentError,
          ),
        );
      }
      return;
    } on CorruptedBackupException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Integrity check failed: ${e.message}'),
            backgroundColor: _accentError,
          ),
        );
      }
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to inspect archive: $e'),
            backgroundColor: _accentError,
          ),
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (!mounted) return;

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified, color: _accentGreen),
            SizedBox(width: 8),
            Text('Backup Verified'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All SHA-256 file checksums verified successfully.',
              style: TextStyle(color: _accentGreen, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Text('• Archive: $originName'),
            Text('• Created: ${inspection.manifest.createdAt.toLocal().toString().substring(0, 16)}'),
            Text('• Total Flights: ${inspection.manifest.flightCount}'),
            Text('• Endorsement Scans: ${inspection.manifest.documentCount}'),
            Text('• Aircraft Models: ${inspection.manifest.aircraftModelCount}'),
            Text('• Archive Size: ${(inspection.totalSizeBytes / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 16),
            const Text(
              'Proceeding will replace your current logbook with this backup. Rollback protection is active.',
              style: TextStyle(color: _accentWarning, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accentGreen),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore Logbook'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Applying restoration with rollback protection...';
    });

    try {
      await backupService.restoreBackup(
        backupBytes: fileBytes,
        passphrase: passphrase,
        preExtractedBackup: inspection.extractedBackup,
      );

      ref.invalidate(databaseProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logbook restored successfully!'),
            backgroundColor: _accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: _accentError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAutoSyncDrive(BackupSettings settings, bool enabled) async {
    final repo = ref.read(backupSettingsRepositoryProvider);
    final updated = settings.copyWith(autoSyncGoogleDrive: enabled);
    await repo.updateSettings(updated);
    ref.invalidate(backupSettingsProvider);

    if (enabled) {
      await BackupWorkmanagerService.schedulePeriodicBackup(
        intervalDays: settings.backupIntervalDays,
      );
    } else if (!settings.autoBackupEnabled) {
      await BackupWorkmanagerService.cancelPeriodicBackup();
    }
  }

  Future<void> _toggleAutoBackup(BackupSettings settings, bool enabled) async {
    final repo = ref.read(backupSettingsRepositoryProvider);
    final updated = settings.copyWith(autoBackupEnabled: enabled);
    await repo.updateSettings(updated);
    ref.invalidate(backupSettingsProvider);

    if (enabled) {
      await BackupWorkmanagerService.schedulePeriodicBackup(
        intervalDays: settings.backupIntervalDays,
      );
    } else if (!settings.autoSyncGoogleDrive) {
      await BackupWorkmanagerService.cancelPeriodicBackup();
    }
  }

  Future<void> _sendTestEmailBackup(BackupSettings settings) async {
    final repo = ref.read(backupSettingsRepositoryProvider);
    final masterPass = await repo.getMasterPassphrase();
    final smtpPass = await repo.getSmtpPassword();

    if (!mounted) return;

    if (masterPass == null || masterPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure a Master Passphrase first.')),
      );
      return;
    }

    if (settings.smtpHost == null || settings.smtpUsername == null || smtpPass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMTP configuration is incomplete.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Sending encrypted backup via SMTP...';
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final encryptedBytes = await backupService.createEncryptedBackup(passphrase: masterPass);

      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = 'spreadlog_backup_$nowStr.spbackup';

      final config = SmtpConfig(
        host: settings.smtpHost!,
        port: settings.smtpPort,
        username: settings.smtpUsername!,
        password: smtpPass,
        useTls: settings.smtpUseTls,
        senderEmail: settings.primaryEmail ?? settings.smtpUsername!,
      );

      final transport = SmtpBackupTransport(config);
      await transport.dispatchBackup(
        encryptedBytes: encryptedBytes,
        suggestedFileName: fileName,
        recipientEmail: settings.primaryEmail,
      );

      await repo.recordBackupResult(timestamp: DateTime.now().toUtc(), status: 'Sent via SMTP');
      ref.invalidate(backupSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test backup dispatched via SMTP to ${settings.primaryEmail ?? settings.smtpUsername}'),
            backgroundColor: _accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMTP dispatch failed: $e'),
            backgroundColor: _accentError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _promptConfigurePassphrase() async {
    final repo = ref.read(backupSettingsRepositoryProvider);
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Master Passphrase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This passphrase encrypts all exported backups. Keep it safe—without it, backups cannot be decrypted.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl1,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Master Passphrase'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl2,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Passphrase'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl1.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Passphrase cannot be empty.')),
                );
                return;
              }
              if (ctrl1.text != ctrl2.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Passphrases do not match.')),
                );
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (success == true) {
      await repo.setMasterPassphrase(ctrl1.text);
      ref.invalidate(backupSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Master Passphrase updated successfully.')),
        );
      }
    }
  }

  Future<String?> _promptEnterPassphraseDialog({
    required String title,
    required String message,
  }) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Passphrase'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptConfigureSmtp(BackupSettings settings) async {
    final hostCtrl = TextEditingController(text: settings.smtpHost ?? '');
    final portCtrl = TextEditingController(text: settings.smtpPort.toString());
    final userCtrl = TextEditingController(text: settings.smtpUsername ?? '');
    final passCtrl = TextEditingController();
    final primaryEmailCtrl = TextEditingController(text: settings.primaryEmail ?? '');
    bool useTls = settings.smtpUseTls;

    final repo = ref.read(backupSettingsRepositoryProvider);
    final existingPass = await repo.getSmtpPassword();
    if (existingPass != null) {
      passCtrl.text = existingPass;
    }

    if (!mounted) return;

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('SMTP Email Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hostCtrl,
                  decoration: const InputDecoration(labelText: 'SMTP Host (e.g. smtp.gmail.com)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: portCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Port (e.g. 587)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(labelText: 'SMTP Username / Login'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'SMTP Password / App Password'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: primaryEmailCtrl,
                  decoration: const InputDecoration(labelText: 'Recipient Email Address'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use TLS'),
                  value: useTls,
                  onChanged: (val) => setDialogState(() => useTls = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save == true) {
      final updated = settings.copyWith(
        smtpHost: hostCtrl.text.trim().isEmpty ? null : hostCtrl.text.trim(),
        smtpPort: int.tryParse(portCtrl.text.trim()) ?? 587,
        smtpUsername: userCtrl.text.trim().isEmpty ? null : userCtrl.text.trim(),
        primaryEmail: primaryEmailCtrl.text.trim().isEmpty ? null : primaryEmailCtrl.text.trim(),
        smtpUseTls: useTls,
      );

      await repo.updateSettings(updated);
      if (passCtrl.text.isNotEmpty) {
        await repo.setSmtpPassword(passCtrl.text);
      }
      ref.invalidate(backupSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMTP configuration saved.')),
        );
      }
    }
  }
}
