import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../flights/presentation/providers/flights_providers.dart';
import '../../data/backup_service.dart';
import '../../data/backup_settings_repository.dart';
import '../../data/backup_workmanager_service.dart';
import '../../data/transports/smtp_backup_transport.dart';
import '../../domain/backup_exceptions.dart';
import '../providers/backup_providers.dart';

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

  bool _isLoading = false;
  String? _loadingMessage;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(backupSettingsProvider);
    final flightsAsync = ref.watch(flightsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Backup & Restore'),
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
              color: Colors.black.withValues(alpha: 0.5),
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
        _buildMasterPassphraseCard(context, settings),
        const SizedBox(height: 16),
        _buildExportCard(context, settings, currentFlightCount),
        const SizedBox(height: 16),
        _buildRestoreCard(context, settings),
        const SizedBox(height: 16),
        _buildAutomatedBackupCard(context, settings),
        const SizedBox(height: 32),
      ],
    );
  }

  // --- CARD 1: MASTER PASSPHRASE ---
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
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Master Passphrase',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isConfigured
                            ? 'Passphrase saved in secure device storage.'
                            : 'No passphrase set. Configure one to protect your exports.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isConfigured ? _accentGreen : _accentWarning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Backups are encrypted using AES-256-GCM with a PBKDF2-derived key (100,000 rounds). '
              'You must remember your passphrase to restore your logbook.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: Icon(isConfigured ? Icons.edit : Icons.key),
              label: Text(isConfigured ? 'Change Master Passphrase' : 'Set Master Passphrase'),
              onPressed: () => _promptConfigurePassphrase(),
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD 2: EXPORT ENCRYPTED BACKUP ---
  Widget _buildExportCard(BuildContext context, BackupSettings settings, int flightCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.upload_file, color: _accentBlue, size: 28),
                SizedBox(width: 12),
                Text(
                  'Export Encrypted Backup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Packages your SQLite database and all scanned endorsement stamps into a tamper-evident, '
              'encrypted .spbackup file.',
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
                label: const Text('Export .spbackup Archive'),
                onPressed: () => _handleExport(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD 3: RESTORE BACKUP ---
  Widget _buildRestoreCard(BuildContext context, BackupSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings_backup_restore, color: _accentPurple, size: 28),
                SizedBox(width: 12),
                Text(
                  'Restore from Backup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an encrypted .spbackup archive. Spreadlog will verify every file\'s SHA-256 hash '
              'before applying changes with automatic rollback safety.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Select .spbackup File'),
                onPressed: () => _handlePickAndRestore(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD 4: AUTOMATED & SMTP BACKUPS ---
  Widget _buildAutomatedBackupCard(BuildContext context, BackupSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule_send, color: _accentGreen, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Automated & Email Backups',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              'Optionally dispatch encrypted backups to your primary and recovery email addresses '
              'via a configured SMTP server.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            if (settings.lastBackupDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last Backup: ${settings.lastBackupDate!.toLocal().toString().substring(0, 16)} '
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
    );
  }

  // --- ACTIONS ---

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
            content: Text('Backup exported successfully (${(encryptedBytes.length / 1024).toStringAsFixed(1)} KB)'),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePickAndRestore() async {
    final pickedFiles = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (pickedFiles.isEmpty) return;

    final pickedFile = pickedFiles.first;
    final fileBytes = await pickedFile.readAsBytes();

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
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (!mounted) return;

    // Show Confirmation Dialog with Manifest details
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
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _accentGreen),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAutoBackup(BackupSettings settings, bool enabled) async {
    final repo = ref.read(backupSettingsRepositoryProvider);
    final updated = settings.copyWith(autoBackupEnabled: enabled);
    await repo.updateSettings(updated);

    if (enabled) {
      await BackupWorkmanagerService.schedulePeriodicBackup(
        intervalDays: settings.backupIntervalDays,
      );
    } else {
      await BackupWorkmanagerService.cancelPeriodicBackup();
    }

    ref.invalidate(backupSettingsProvider);
  }

  Future<void> _sendTestEmailBackup(BackupSettings settings) async {
    final repo = ref.read(backupSettingsRepositoryProvider);
    final pass = await repo.getMasterPassphrase();
    final smtpPass = await repo.getSmtpPassword();

    if (!mounted) return;

    if (pass == null || pass.isEmpty) {
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
      final encryptedBytes = await backupService.createEncryptedBackup(passphrase: pass);

      final config = SmtpConfig(
        host: settings.smtpHost!,
        port: settings.smtpPort,
        username: settings.smtpUsername!,
        password: smtpPass,
        useTls: settings.smtpUseTls,
        senderEmail: settings.primaryEmail ?? settings.smtpUsername!,
        recoveryEmail: settings.recoveryEmail,
      );

      final transport = SmtpBackupTransport(config);
      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      await transport.dispatchBackup(
        encryptedBytes: encryptedBytes,
        suggestedFileName: 'spreadlog_backup_$nowStr.spbackup',
      );

      await repo.recordBackupResult(timestamp: DateTime.now().toUtc(), status: 'Sent via SMTP');
      ref.invalidate(backupSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test backup sent successfully via email!'),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- DIALOGS ---

  Future<void> _promptConfigurePassphrase() async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Master Passphrase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a strong passphrase to encrypt your backups. If you lose this passphrase, '
              'encrypted backups cannot be restored.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passphrase',
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Passphrase',
                prefixIcon: Icon(Icons.key_outlined),
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
              if (controller.text.isEmpty) return;
              if (controller.text != confirmController.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Passphrases do not match.')),
                );
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Save Passphrase'),
          ),
        ],
      ),
    );

    if (success == true) {
      final repo = ref.read(backupSettingsRepositoryProvider);
      await repo.setMasterPassphrase(controller.text);
      ref.invalidate(backupSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Master Passphrase configured!'),
            backgroundColor: _accentGreen,
          ),
        );
      }
    }
  }

  Future<String?> _promptEnterPassphraseDialog({
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();

    return await showDialog<String>(
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
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Passphrase',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
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
    final primaryEmailCtrl = TextEditingController(text: settings.primaryEmail ?? '');
    final recoveryEmailCtrl = TextEditingController(text: settings.recoveryEmail ?? '');
    final passCtrl = TextEditingController();

    final repo = ref.read(backupSettingsRepositoryProvider);
    final existingPass = await repo.getSmtpPassword();
    if (existingPass != null) {
      passCtrl.text = existingPass;
    }

    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                decoration: const InputDecoration(labelText: 'Port (e.g. 587 or 465)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(labelText: 'Username / Auth Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password / App Password'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: primaryEmailCtrl,
                decoration: const InputDecoration(labelText: 'Primary Recipient Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: recoveryEmailCtrl,
                decoration: const InputDecoration(labelText: 'Recovery Email (Optional CC)'),
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
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final updated = settings.copyWith(
        smtpHost: hostCtrl.text.trim().isEmpty ? null : hostCtrl.text.trim(),
        smtpPort: int.tryParse(portCtrl.text.trim()) ?? 587,
        smtpUsername: userCtrl.text.trim().isEmpty ? null : userCtrl.text.trim(),
        primaryEmail: primaryEmailCtrl.text.trim().isEmpty ? null : primaryEmailCtrl.text.trim(),
        recoveryEmail: recoveryEmailCtrl.text.trim().isEmpty ? null : recoveryEmailCtrl.text.trim(),
      );

      await repo.updateSettings(updated);
      if (passCtrl.text.isNotEmpty) {
        await repo.setSmtpPassword(passCtrl.text);
      }
      ref.invalidate(backupSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMTP configuration saved.'),
            backgroundColor: _accentGreen,
          ),
        );
      }
    }
  }
}
