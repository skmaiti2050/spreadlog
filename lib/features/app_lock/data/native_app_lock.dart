import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../domain/app_lock.dart';

const _channel = MethodChannel('com.spreadlog.app/app_lock');

class NativeDeviceAuthenticator implements DeviceAuthenticator {
  final LocalAuthentication authentication;
  NativeDeviceAuthenticator({LocalAuthentication? authentication})
    : authentication = authentication ?? LocalAuthentication();

  @override
  Future<AuthenticationResult> authenticate(String reason) async {
    try {
      final success = await authentication.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: false,
      );
      return success
          ? AuthenticationResult.success
          : AuthenticationResult.canceled;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout => AuthenticationResult.canceled,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          AuthenticationResult.lockedOut,
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware =>
          AuthenticationResult.unavailable,
        _ => AuthenticationResult.failed,
      };
    } catch (_) {
      return AuthenticationResult.failed;
    }
  }

  @override
  Future<void> openSecuritySettings() =>
      _channel.invokeMethod<void>('openSecuritySettings');
}

/// Device-only settings: never part of SQLite or portable backup exports.
class SecureAppLockSettingsStore implements AppLockSettingsStore {
  static const _key = 'app_lock_settings';
  final FlutterSecureStorage storage;
  const SecureAppLockSettingsStore({
    this.storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: false,
        storageNamespace: 'spreadlog_app_lock',
      ),
    ),
  });

  @override
  Future<AppLockSettings> load() async {
    final raw = await storage.read(key: _key);
    if (raw == null) {
      final protected = await _channel.invokeMethod<bool>(
        'isProtectionEnabled',
      );
      if (protected != false) {
        throw StateError('Device lock settings are unavailable');
      }
      return const AppLockSettings();
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AppLockSettings(
      enabled: json['enabled'] as bool,
      delay: RelockDelay.values.byName(json['delay'] as String),
    );
  }

  @override
  Future<void> save(AppLockSettings settings) => storage.write(
    key: _key,
    value: jsonEncode({
      'enabled': settings.enabled,
      'delay': settings.delay.name,
    }),
  );

  @override
  Future<void> protectPreviews(bool enabled) =>
      _channel.invokeMethod<void>('setProtectionEnabled', enabled);
}
