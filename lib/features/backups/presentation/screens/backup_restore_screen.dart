import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../flights/presentation/providers/flights_providers.dart';
import '../../data/backup_intent_service.dart';
import '../../data/backup_service.dart';
import '../../data/backup_settings_repository.dart';
import '../../data/backup_workmanager_service.dart';
import '../../data/transports/google_drive_backup_transport.dart';
import '../../data/transports/smtp_backup_transport.dart';
import '../../domain/backup_exceptions.dart';
import '../../domain/backup_encryptor.dart';
import '../../domain/auto_backup_status.dart';
import '../../domain/backup_file_name.dart';
import '../providers/backup_providers.dart';
import '../providers/google_auth_providers.dart';
import '../widgets/google_sign_in_button.dart';
import '../../../../core/utils/plural.dart';
import '../../../../core/layout/responsive.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  final String? initialFilePath;

  const BackupRestoreScreen({super.key, this.initialFilePath});

  /// Tracks if the screen is currently mounted and active.
  static bool isScreenActive = false;

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  // Accents are tuned per brightness: the mid-tone shades that read well on
  // the dark themes fall below 3:1 contrast on the light theme's surfaces.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _accentGreen =>
      _isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
  Color get _accentWarning =>
      _isDark ? const Color(0xFFFFA726) : const Color(0xFFB45309);
  Color get _accentError =>
      _isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
  Color get _accentBlue =>
      _isDark ? const Color(0xFF42A5F5) : const Color(0xFF1565C0);
  Color get _accentPurple =>
      _isDark ? const Color(0xFFAB47BC) : const Color(0xFF7B1FA2);

  // Snackbar backgrounds stay dark on every theme so the theme's white
  // snackbar text keeps at least 4.5:1 contrast.
  static const Color _snackSuccess = Color(0xFF2E7D32);
  static const Color _snackError = Color(0xFFC62828);
  static const Color _snackWarning = Color(0xFFB45309);

  /// Secondary text that stays legible on every theme's card surface.
  Color get _mutedText => Theme.of(context).colorScheme.onSurfaceVariant;

  int _selectedSegment = 0; // 0: Local/Offline, 1: Google Drive, 2: Email
  bool _isLoading = false;
  String? _loadingMessage;

  List<GoogleDriveBackupItem>? _driveBackups;
  bool _isLoadingDriveBackups = false;
  // Whether the Drive/Gmail scopes are granted; null until checked. Cached
  // so the banner doesn't ask Google on every rebuild.
  bool? _hasGoogleScopes;
  StreamSubscription<String>? _backupIntentSub;

  @override
  void initState() {
    super.initState();
    BackupRestoreScreen.isScreenActive = true;

    // Listen for incoming backup files while this screen is active
    _backupIntentSub = BackupIntentService.onBackupFileReceived.listen((path) {
      if (mounted) {
        _restoreFromPath(path);
      }
    });

    // Silently attempt Google sign-in on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trySilentGoogleSignIn();
      if (widget.initialFilePath != null) {
        _restoreFromPath(widget.initialFilePath!);
      }
    });
  }

  @override
  void dispose() {
    BackupRestoreScreen.isScreenActive = false;
    _backupIntentSub?.cancel();
    super.dispose();
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
    // Sign-in can be reported both by the call that made it and by the user
    // stream, so a second request while one is running is dropped.
    if (!authService.isSignedIn || _isLoadingDriveBackups) return;

    setState(() => _isLoadingDriveBackups = true);
    try {
      final hasAccess = await authService.canAccessScopes();
      if (mounted) setState(() => _hasGoogleScopes = hasAccess);
      if (!hasAccess) {
        if (mounted) setState(() => _driveBackups = null);
        return;
      }
      final driveTransport = ref.read(googleDriveTransportProvider);
      final backups = await driveTransport.listBackups();
      if (mounted) setState(() => _driveBackups = backups);
    } catch (e) {
      debugPrint('Loading Drive backups failed: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDriveBackups = false);
    }
  }

  /// Makes sure the Drive and Gmail scopes are granted, asking the user if
  /// needed. Shows [deniedMessage] and returns false when they aren't.
  Future<bool> _ensureGoogleScopes(String deniedMessage) async {
    final authService = ref.read(googleAuthServiceProvider);
    if (await authService.canAccessScopes()) return true;
    final granted = await authService.requestScopes();
    if (!mounted) return granted;
    setState(() => _hasGoogleScopes = granted);
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(deniedMessage), backgroundColor: _snackWarning),
      );
    }
    return granted;
  }

  @override
  Widget build(BuildContext context) {
    // On web, silent sign-in is reported only through this stream, after
    // _trySilentGoogleSignIn has already returned null.
    ref.listen(googleUserStreamProvider, (previous, next) {
      final user = next.value;
      if (user == null) {
        setState(() => _hasGoogleScopes = null);
      } else if (previous?.value?.id != user.id) {
        unawaited(_loadDriveBackups());
      }
    });
    final settingsAsync = ref.watch(backupSettingsProvider);
    final flightsAsync = ref.watch(flightsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Cloud Sync Hub')),
      body: Stack(
        children: [
          settingsAsync.when(
            data: (settings) => _buildContent(
              context,
              settings,
              flightsAsync.value?.length ?? 0,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Error loading settings: $err')),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
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

  Widget _buildContent(
    BuildContext context,
    BackupSettings settings,
    int currentFlightCount,
  ) {
    return ContentWidth(
      child: ListView(
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
                  label: Text('Local'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.cloud_sync_outlined),
                  label: Text('Drive'),
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
      ),
    );
  }

  // ==========================================
  // SECTION: MASTER PASSPHRASE
  // ==========================================
  Widget _buildMasterPassphraseCard(
    BuildContext context,
    BackupSettings settings,
  ) {
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isConfigured
                            ? 'Passphrase saved in hardware-backed secure storage.'
                            : 'Not set yet. You will be asked for one when you create a backup.',
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
  Widget _buildExportCard(
    BuildContext context,
    BackupSettings settings,
    int flightCount,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: _accentBlue, size: 26),
                const SizedBox(width: 12),
                const Text(
                  'Export Local Archive (.spbackup)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Packages your SQLite database and scanned endorsement stamps into a tamper-evident, '
              'AES-256 encrypted file. Works 100% offline with zero internet required.',
              style: TextStyle(fontSize: 13, color: _mutedText),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  avatar: const Icon(Icons.flight, size: 16),
                  label: Text(plural(flightCount, 'flight')),
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
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Save'),
                    onPressed: () => _handleSaveToDevice(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share File'),
                    onPressed: () => _handleExport(),
                  ),
                ),
              ],
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
            Row(
              children: [
                Icon(
                  Icons.settings_backup_restore,
                  color: _accentPurple,
                  size: 26,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Restore from Local File',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select an encrypted .spbackup file from your device storage or files app. '
              'Every file checksum is verified before applying changes with rollback safety.',
              style: TextStyle(fontSize: 13, color: _mutedText),
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
  Widget _buildGoogleDriveSyncCard(
    BuildContext context,
    BackupSettings settings,
  ) {
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
                      backgroundColor: isSignedIn
                          ? Colors.blue.shade800
                          : Colors.grey.shade800,
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
                            isSignedIn
                                ? (user.displayName ?? 'Google Account')
                                : 'Google Cloud Sync',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isSignedIn
                                ? user.email
                                : 'Not connected to Google Drive',
                            style: TextStyle(
                              fontSize: 13,
                              color: isSignedIn ? _accentGreen : _mutedText,
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
                      buildGoogleSignInButton(onPressed: _handleGoogleSignIn),
                  ],
                ),
                if (!isSignedIn) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Connect your Google Account to automatically store and sync your AES-256 encrypted '
                    'flight logbook in Google Drive. Zero passwords stored, and only Spreadlog files are accessed.',
                    style: TextStyle(fontSize: 12, color: _mutedText),
                  ),
                ],
                if (isSignedIn && _hasGoogleScopes == false) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Colors.amber,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            // Web tokens don't survive a reload, so there it
                            // is usually a reconnect, not a first grant.
                            kIsWeb
                                ? 'Reconnect Google Drive to sync and see your backups.'
                                : 'Google Drive permission required to sync files.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () async {
                            final ok = await authService.requestScopes();
                            if (ok && mounted) await _loadDriveBackups();
                          },
                          child: const Text(kIsWeb ? 'Connect' : 'Authorize'),
                        ),
                      ],
                    ),
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
                  // Browsers can't run the app in the background, and Google
                  // gives web pages no refresh token, so this is app-only.
                  if (kIsWeb)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline),
                      title: Text('Automatic Background Sync'),
                      subtitle: Text(
                        'Scheduled Drive backups run in the Android and iOS '
                        'apps. On the web, use Backup to Google Drive Now.',
                      ),
                    )
                  else ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Automatic Background Sync'),
                      subtitle: const Text(
                        'Silently upload encrypted backups to Google Drive in the background via WorkManager.',
                      ),
                      value: settings.autoSyncGoogleDrive,
                      onChanged: (val) => _toggleAutoSyncDrive(settings, val),
                    ),
                    _buildDriveAutoBackupStatus(settings),
                  ],
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          _hasGoogleScopes == false
                              ? 'Allow Google Drive access above to see your backups.'
                              : 'No cloud backups found in Google Drive.\nTap "Backup to Google Drive Now" to upload one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _mutedText),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _driveBackups!.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _driveBackups![index];
                        final dateStr = item.createdTime != null
                            ? item.createdTime!.toLocal().toString().substring(
                                0,
                                16,
                              )
                            : 'Unknown date';
                        final sizeKb = (item.sizeBytes / 1024).toStringAsFixed(
                          1,
                        );

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.cloud_done, color: _accentGreen),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text('$dateStr • $sizeKb KB'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.restore, color: _accentBlue),
                                tooltip: 'Restore from this backup',
                                onPressed: () => _handleRestoreFromDrive(item),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: _accentError,
                                ),
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
  Widget _buildEmailDispatchCard(
    BuildContext context,
    BackupSettings settings,
  ) {
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
                Row(
                  children: [
                    Icon(Icons.mark_email_read, color: _accentBlue, size: 26),
                    const SizedBox(width: 12),
                    const Text(
                      'Email Backup to Myself (Google)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sends the AES-256 encrypted logbook backup directly to your Gmail inbox via the Google REST API. '
                  'Zero password configuration or SMTP ports required.',
                  style: TextStyle(fontSize: 13, color: _mutedText),
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
                      label: const Text(
                        'Sign in with Google to Email Yourself',
                      ),
                      onPressed: _handleGoogleSignIn,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Browsers cannot open raw SMTP sockets and workmanager has no web
        // implementation, so custom SMTP and scheduled backups are app-only.
        if (kIsWeb)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Custom SMTP server'),
              subtitle: Text(
                'Sending through your own mail server and scheduled email '
                'backups are available in the Android and iOS apps.',
              ),
            ),
          )
        else
          // Custom SMTP Fallback Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: _accentWarning, size: 26),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Custom SMTP Server (Advanced)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: settings.autoBackupEnabled,
                        onChanged: (enabled) =>
                            _toggleAutoBackup(settings, enabled),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For pilots using custom email domains, Outlook, or private mail servers. '
                    'Requires custom SMTP host, port, TLS, and mailbox credentials.',
                    style: TextStyle(fontSize: 13, color: _mutedText),
                  ),
                  if (settings.lastBackupDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last Email: ${settings.lastBackupDate!.toLocal().toString().substring(0, 16)} '
                      '(${settings.lastBackupStatus ?? "OK"})',
                      style: TextStyle(fontSize: 12, color: _accentGreen),
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
                      if (settings.smtpHost != null &&
                          settings.smtpHost!.isNotEmpty) ...[
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
        await repo.updateSettings(
          settings.copyWith(googleAccountEmail: resolvedUser.email),
        );
        ref.invalidate(backupSettingsProvider);
        await _loadDriveBackups();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to Google as ${resolvedUser.email}'),
              backgroundColor: _snackSuccess,
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
        await repo.updateSettings(
          settings.copyWith(googleAccountEmail: resolvedUser.email),
        );
        ref.invalidate(backupSettingsProvider);
        await _loadDriveBackups();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: _snackError,
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Signed out of Google.')));
    }
  }

  Future<void> _handleBackupToDrive() async {
    if (!await _ensureGoogleScopes(
      'Google Drive permission is required to upload backups.',
    )) {
      return;
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
      _loadingMessage =
          'Creating encrypted backup & uploading to Google Drive...';
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final encryptedBytes = await backupService.createEncryptedBackup(
        passphrase: passphrase,
      );

      final fileName = backupFileName(DateTime.now());

      final driveTransport = ref.read(googleDriveTransportProvider);
      await driveTransport.dispatchBackup(
        encryptedBytes: encryptedBytes,
        suggestedFileName: fileName,
      );

      await repo.recordBackupResult(
        timestamp: DateTime.now().toUtc(),
        status: 'Google Drive Sync OK',
      );
      ref.invalidate(backupSettingsProvider);
      await _loadDriveBackups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup saved to Google Drive ($fileName • ${(encryptedBytes.length / 1024).toStringAsFixed(1)} KB)',
            ),
            backgroundColor: _snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Drive backup failed: $e'),
            backgroundColor: _snackError,
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
            backgroundColor: _snackError,
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
        content: Text(
          'Are you sure you want to delete ${item.name} from Google Drive?',
        ),
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
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: _snackError,
          ),
        );
      }
    }
  }

  Future<void> _handleSendGmailBackup(String recipientEmail) async {
    if (!await _ensureGoogleScopes(
      'Gmail permission is required to send backups.',
    )) {
      return;
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
      _loadingMessage =
          'Sending encrypted backup to $recipientEmail via Gmail API...';
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final encryptedBytes = await backupService.createEncryptedBackup(
        passphrase: passphrase,
      );

      final fileName = backupFileName(DateTime.now());

      final gmailTransport = ref.read(gmailTransportProvider);
      await gmailTransport.dispatchBackup(
        encryptedBytes: encryptedBytes,
        suggestedFileName: fileName,
        recipientEmail: recipientEmail,
      );

      await repo.recordBackupResult(
        timestamp: DateTime.now().toUtc(),
        status: 'Gmail Dispatch OK',
      );
      ref.invalidate(backupSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Encrypted backup successfully sent to $recipientEmail!',
            ),
            backgroundColor: _snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gmail dispatch failed: $e'),
            backgroundColor: _snackError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSaveToDevice() async {
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
      final encryptedBytes = await backupService.createEncryptedBackup(
        passphrase: passphrase,
      );

      final fileName = backupFileName(DateTime.now());

      if (!mounted) return;

      setState(() {
        _loadingMessage = 'Selecting save location...';
      });

      final resultUri = await FilePicker.saveFile(
        dialogTitle: 'Save Encrypted Backup',
        fileName: fileName,
        bytes: encryptedBytes,
      );

      if (resultUri != null) {
        await repo.recordBackupResult(
          timestamp: DateTime.now().toUtc(),
          status: 'Saved to Device',
        );
        ref.invalidate(backupSettingsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup saved successfully: $fileName'),
              backgroundColor: _snackSuccess,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: _snackError,
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
      final encryptedBytes = await backupService.createEncryptedBackup(
        passphrase: passphrase,
      );

      final fileName = backupFileName(DateTime.now());

      if (!mounted) return;

      setState(() {
        _loadingMessage = 'Exporting via OS Share...';
      });

      final transport = ref.read(shareBackupTransportProvider);
      await transport.dispatchBackup(
        encryptedBytes: encryptedBytes,
        suggestedFileName: fileName,
      );

      await repo.recordBackupResult(
        timestamp: DateTime.now().toUtc(),
        status: 'Exported',
      );
      ref.invalidate(backupSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup exported successfully (${(encryptedBytes.length / 1024).toStringAsFixed(1)} KB)',
            ),
            backgroundColor: _snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: _snackError,
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
    try {
      final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      // Android filters by MIME type, and .spbackup has none, so it would fall
      // back to */*. 'bin' maps to application/octet-stream, the type Android
      // reports for unknown extensions: the picker then hides photos, PDFs, etc.
      final android =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      final files = await FilePicker.pickFiles(
        type: ios ? FileType.any : FileType.custom,
        allowedExtensions: ios
            ? null
            : ['spbackup', 'spreadlog', if (android) 'bin'],
      );
      if (files.isEmpty || !mounted) return;
      final bytes = await files.first.readAsBytes();
      if (!mounted) return;
      await _performRestore(bytes, originName: files.first.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open backup: $e')));
      }
    }
  }

  Future<void> _restoreFromPath(String path) async {
    final bytes = await BackupIntentService.readFileBytes(path);
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not read backup file at $path'),
            backgroundColor: _snackError,
          ),
        );
      }
      return;
    }

    final fileName = BackupIntentService.getFileName(path);
    await _performRestore(bytes, originName: fileName);
  }

  Future<void> _performRestore(
    Uint8List fileBytes, {
    String originName = 'archive',
  }) async {
    if (!mounted || _isLoading) return;
    if (fileBytes.length < 4 ||
        !List.generate(
          4,
          (i) => fileBytes[i] == BackupEncryptor.magicBytes[i],
        ).every((match) => match)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This file is not a Spreadlog encrypted backup.'),
        ),
      );
      return;
    }

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
            backgroundColor: _snackError,
          ),
        );
      }
      return;
    } on CorruptedBackupException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Integrity check failed: ${e.message}'),
            backgroundColor: _snackError,
          ),
        );
      }
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to inspect archive: $e'),
            backgroundColor: _snackError,
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
        title: Row(
          children: [
            Icon(Icons.verified, color: _accentGreen),
            const SizedBox(width: 8),
            const Text('Backup Verified'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All SHA-256 file checksums verified successfully.',
              style: TextStyle(
                color: _accentGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            Text('• Archive: $originName'),
            Text(
              '• Created: ${inspection.manifest.createdAt.toLocal().toString().substring(0, 16)}',
            ),
            Text('• Total Flights: ${inspection.manifest.flightCount}'),
            Text(
              '• Endorsement Page Images: ${inspection.manifest.documentCount}',
            ),
            Text(
              '• Aircraft Models: ${inspection.manifest.aircraftModelCount}',
            ),
            Text(
              '• Archive Size: ${(inspection.totalSizeBytes / 1024).toStringAsFixed(1)} KB',
            ),
            const SizedBox(height: 16),
            Text(
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

    if (shouldProceed != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Applying restoration with rollback protection...';
    });

    // Captured now: `ref` is unusable if the screen is disposed mid-restore.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await backupService.restoreBackup(
        backupBytes: fileBytes,
        passphrase: passphrase,
        preExtractedBackup: inspection.extractedBackup,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logbook restored successfully!'),
            backgroundColor: _snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: _snackError,
          ),
        );
      }
    } finally {
      // restoreBackup closes the live connection before swapping files, so
      // reopen it even when the restore fails and the old database is rolled back.
      container.invalidate(databaseProvider);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAutoSyncDrive(
    BackupSettings settings,
    bool enabled,
  ) async {
    final repo = ref.read(backupSettingsRepositoryProvider);
    final updated = settings.copyWith(autoSyncGoogleDrive: enabled);
    await repo.updateSettings(updated);
    ref.invalidate(backupSettingsProvider);

    if (enabled) {
      await _schedulePeriodicBackup(settings.backupIntervalDays);
    } else if (!settings.autoBackupEnabled) {
      await BackupWorkmanagerService.cancelPeriodicBackup();
    }
  }

  /// Result of the last background Drive backup, under its switch.
  Widget _buildDriveAutoBackupStatus(BackupSettings settings) {
    final status = driveAutoBackupStatus(
      enabled: settings.autoSyncGoogleDrive,
      lastRun: settings.lastDriveSyncDate,
      error: settings.lastDriveSyncError,
    );
    if (status == null) return const SizedBox.shrink();
    final (icon, color) = switch (status.succeeded) {
      true => (Icons.check_circle_outline, _accentGreen),
      false => (Icons.error_outline, _accentWarning),
      null => (Icons.schedule, _mutedText),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status.message,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _schedulePeriodicBackup(int intervalDays) async {
    final scheduled = await BackupWorkmanagerService.schedulePeriodicBackup(
      intervalDays: intervalDays,
    );
    if (!scheduled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not schedule automatic backups on this device.'),
          backgroundColor: _snackWarning,
        ),
      );
    }
  }

  Future<void> _toggleAutoBackup(BackupSettings settings, bool enabled) async {
    final repo = ref.read(backupSettingsRepositoryProvider);
    final updated = settings.copyWith(autoBackupEnabled: enabled);
    await repo.updateSettings(updated);
    ref.invalidate(backupSettingsProvider);

    if (enabled) {
      await _schedulePeriodicBackup(settings.backupIntervalDays);
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
        const SnackBar(
          content: Text('Please configure a Master Passphrase first.'),
        ),
      );
      return;
    }

    if (settings.smtpHost == null ||
        settings.smtpUsername == null ||
        smtpPass == null) {
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
      final encryptedBytes = await backupService.createEncryptedBackup(
        passphrase: masterPass,
      );

      final fileName = backupFileName(DateTime.now());

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

      await repo.recordBackupResult(
        timestamp: DateTime.now().toUtc(),
        status: 'Sent via SMTP',
      );
      ref.invalidate(backupSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test backup dispatched via SMTP to ${settings.primaryEmail ?? settings.smtpUsername}',
            ),
            backgroundColor: _snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMTP dispatch failed: $e'),
            backgroundColor: _snackError,
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
            Text(
              'This passphrase encrypts all exported backups. Keep it safe—without it, backups cannot be decrypted.',
              style: TextStyle(fontSize: 13, color: _mutedText),
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
              decoration: const InputDecoration(
                labelText: 'Confirm Passphrase',
              ),
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
          const SnackBar(
            content: Text('Master Passphrase updated successfully.'),
          ),
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
            Text(message, style: TextStyle(fontSize: 13, color: _mutedText)),
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
    final primaryEmailCtrl = TextEditingController(
      text: settings.primaryEmail ?? '',
    );
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
                  decoration: const InputDecoration(
                    labelText: 'SMTP Host (e.g. smtp.gmail.com)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: portCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port (e.g. 587)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'SMTP Username / Login',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'SMTP Password / App Password',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: primaryEmailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Email Address',
                  ),
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
        smtpUsername: userCtrl.text.trim().isEmpty
            ? null
            : userCtrl.text.trim(),
        primaryEmail: primaryEmailCtrl.text.trim().isEmpty
            ? null
            : primaryEmailCtrl.text.trim(),
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
