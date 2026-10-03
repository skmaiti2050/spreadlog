import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration options for automated backups and email delivery.
class BackupSettings {
  final bool hasMasterPassphrase;
  final bool autoBackupEnabled;
  final int backupIntervalDays;
  final String? primaryEmail;
  final String? recoveryEmail;
  final String? smtpHost;
  final int smtpPort;
  final String? smtpUsername;
  final bool smtpUseTls;
  final DateTime? lastBackupDate;
  final String? lastBackupStatus;
  final bool autoSyncGoogleDrive;
  final String preferredBackupMethod;
  final String? googleAccountEmail;

  const BackupSettings({
    required this.hasMasterPassphrase,
    this.autoBackupEnabled = false,
    this.backupIntervalDays = 7,
    this.primaryEmail,
    this.recoveryEmail,
    this.smtpHost,
    this.smtpPort = 587,
    this.smtpUsername,
    this.smtpUseTls = true,
    this.lastBackupDate,
    this.lastBackupStatus,
    this.autoSyncGoogleDrive = false,
    this.preferredBackupMethod = 'local',
    this.googleAccountEmail,
  });

  BackupSettings copyWith({
    bool? hasMasterPassphrase,
    bool? autoBackupEnabled,
    int? backupIntervalDays,
    String? primaryEmail,
    String? recoveryEmail,
    String? smtpHost,
    int? smtpPort,
    String? smtpUsername,
    bool? smtpUseTls,
    DateTime? lastBackupDate,
    String? lastBackupStatus,
    bool? autoSyncGoogleDrive,
    String? preferredBackupMethod,
    String? googleAccountEmail,
  }) {
    return BackupSettings(
      hasMasterPassphrase: hasMasterPassphrase ?? this.hasMasterPassphrase,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupIntervalDays: backupIntervalDays ?? this.backupIntervalDays,
      primaryEmail: primaryEmail ?? this.primaryEmail,
      recoveryEmail: recoveryEmail ?? this.recoveryEmail,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpUseTls: smtpUseTls ?? this.smtpUseTls,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      lastBackupStatus: lastBackupStatus ?? this.lastBackupStatus,
      autoSyncGoogleDrive: autoSyncGoogleDrive ?? this.autoSyncGoogleDrive,
      preferredBackupMethod: preferredBackupMethod ?? this.preferredBackupMethod,
      googleAccountEmail: googleAccountEmail ?? this.googleAccountEmail,
    );
  }
}

/// Repository for persisting backup settings and sensitive master passphrase / credentials.
class BackupSettingsRepository {
  static const String _keyMasterPassphrase = 'sp_master_passphrase';
  static const String _keySmtpPassword = 'sp_smtp_password';

  static const String _prefAutoBackupEnabled = 'sp_auto_backup_enabled';
  static const String _prefBackupIntervalDays = 'sp_backup_interval_days';
  static const String _prefPrimaryEmail = 'sp_primary_email';
  static const String _prefRecoveryEmail = 'sp_recovery_email';
  static const String _prefSmtpHost = 'sp_smtp_host';
  static const String _prefSmtpPort = 'sp_smtp_port';
  static const String _prefSmtpUsername = 'sp_smtp_username';
  static const String _prefSmtpUseTls = 'sp_smtp_use_tls';
  static const String _prefLastBackupDate = 'sp_last_backup_date';
  static const String _prefLastBackupStatus = 'sp_last_backup_status';
  static const String _prefAutoSyncGoogleDrive = 'sp_auto_sync_google_drive';
  static const String _prefPreferredBackupMethod = 'sp_preferred_backup_method';
  static const String _prefGoogleAccountEmail = 'sp_google_account_email';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferencesAsync _prefs;

  BackupSettingsRepository({
    FlutterSecureStorage? secureStorage,
    SharedPreferencesAsync? prefs,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _prefs = prefs ?? SharedPreferencesAsync();

  /// Loads the current configuration.
  Future<BackupSettings> loadSettings() async {
    final pass = await _secureStorage.read(key: _keyMasterPassphrase);
    final autoEnabled = await _prefs.getBool(_prefAutoBackupEnabled) ?? false;
    final interval = await _prefs.getInt(_prefBackupIntervalDays) ?? 7;
    final primary = await _prefs.getString(_prefPrimaryEmail);
    final recovery = await _prefs.getString(_prefRecoveryEmail);
    final host = await _prefs.getString(_prefSmtpHost);
    final port = await _prefs.getInt(_prefSmtpPort) ?? 587;
    final user = await _prefs.getString(_prefSmtpUsername);
    final useTls = await _prefs.getBool(_prefSmtpUseTls) ?? true;
    final lastDateStr = await _prefs.getString(_prefLastBackupDate);
    final lastStatus = await _prefs.getString(_prefLastBackupStatus);
    final autoSyncDrive = await _prefs.getBool(_prefAutoSyncGoogleDrive) ?? false;
    final preferredMethod = await _prefs.getString(_prefPreferredBackupMethod) ?? 'local';
    final googleEmail = await _prefs.getString(_prefGoogleAccountEmail);

    final lastDate = lastDateStr != null ? DateTime.tryParse(lastDateStr) : null;

    return BackupSettings(
      hasMasterPassphrase: pass != null && pass.isNotEmpty,
      autoBackupEnabled: autoEnabled,
      backupIntervalDays: interval,
      primaryEmail: primary,
      recoveryEmail: recovery,
      smtpHost: host,
      smtpPort: port,
      smtpUsername: user,
      smtpUseTls: useTls,
      lastBackupDate: lastDate,
      lastBackupStatus: lastStatus,
      autoSyncGoogleDrive: autoSyncDrive,
      preferredBackupMethod: preferredMethod,
      googleAccountEmail: googleEmail,
    );
  }

  /// Sets or updates the master passphrase in secure storage.
  Future<void> setMasterPassphrase(String passphrase) async {
    await _secureStorage.write(key: _keyMasterPassphrase, value: passphrase);
  }

  /// Retrieves the master passphrase if configured.
  Future<String?> getMasterPassphrase() async {
    return await _secureStorage.read(key: _keyMasterPassphrase);
  }

  /// Clears the master passphrase.
  Future<void> clearMasterPassphrase() async {
    await _secureStorage.delete(key: _keyMasterPassphrase);
  }

  /// Sets or updates the SMTP password in secure storage.
  Future<void> setSmtpPassword(String password) async {
    await _secureStorage.write(key: _keySmtpPassword, value: password);
  }

  /// Retrieves the SMTP password.
  Future<String?> getSmtpPassword() async {
    return await _secureStorage.read(key: _keySmtpPassword);
  }

  /// Updates preferences.
  Future<void> updateSettings(BackupSettings settings) async {
    await _prefs.setBool(_prefAutoBackupEnabled, settings.autoBackupEnabled);
    await _prefs.setInt(_prefBackupIntervalDays, settings.backupIntervalDays);
    if (settings.primaryEmail != null) {
      await _prefs.setString(_prefPrimaryEmail, settings.primaryEmail!);
    } else {
      await _prefs.remove(_prefPrimaryEmail);
    }
    if (settings.recoveryEmail != null) {
      await _prefs.setString(_prefRecoveryEmail, settings.recoveryEmail!);
    } else {
      await _prefs.remove(_prefRecoveryEmail);
    }
    if (settings.smtpHost != null) {
      await _prefs.setString(_prefSmtpHost, settings.smtpHost!);
    } else {
      await _prefs.remove(_prefSmtpHost);
    }
    await _prefs.setInt(_prefSmtpPort, settings.smtpPort);
    if (settings.smtpUsername != null) {
      await _prefs.setString(_prefSmtpUsername, settings.smtpUsername!);
    } else {
      await _prefs.remove(_prefSmtpUsername);
    }
    await _prefs.setBool(_prefSmtpUseTls, settings.smtpUseTls);
    await _prefs.setBool(_prefAutoSyncGoogleDrive, settings.autoSyncGoogleDrive);
    await _prefs.setString(_prefPreferredBackupMethod, settings.preferredBackupMethod);
    if (settings.googleAccountEmail != null) {
      await _prefs.setString(_prefGoogleAccountEmail, settings.googleAccountEmail!);
    } else {
      await _prefs.remove(_prefGoogleAccountEmail);
    }
  }

  /// Records the outcome of a backup run.
  Future<void> recordBackupResult({
    required DateTime timestamp,
    required String status,
  }) async {
    await _prefs.setString(_prefLastBackupDate, timestamp.toIso8601String());
    await _prefs.setString(_prefLastBackupStatus, status);
  }
}
