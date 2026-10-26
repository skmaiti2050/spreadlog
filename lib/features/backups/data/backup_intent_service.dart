import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service managing OS intent requests when the user taps or opens a .spbackup or .spreadlog file.
class BackupIntentService {
  static const MethodChannel _channel = MethodChannel('com.spreadlog.app/backup_intent');

  static final StreamController<String> _fileController = StreamController<String>.broadcast();

  static bool _initialized = false;

  /// Stream of file paths received while the application is active or resumed.
  static Stream<String> get onBackupFileReceived => _fileController.stream;

  /// Initializes the MethodChannel listener for incoming intents.
  ///
  /// [onInvalidFile] fires when the OS opened a file with Spreadlog that is not
  /// a Spreadlog backup (Android offers the app for every unknown file type).
  static void initialize({
    void Function(String filePath)? onFileReceived,
    void Function()? onInvalidFile,
  }) {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onInvalidFileReceived') {
        onInvalidFile?.call();
      } else if (call.method == 'onBackupFileReceived') {
        final filePath = call.arguments as String?;
        if (filePath != null && filePath.isNotEmpty) {
          debugPrint('BackupIntentService: Incoming backup file: $filePath');
          _fileController.add(filePath);
          onFileReceived?.call(filePath);
        }
      }
    });
  }

  /// Checks if the app was launched by tapping an external backup file.
  static Future<String?> getPendingBackupPath() async {
    if (kIsWeb) return null;
    try {
      final path = await _channel.invokeMethod<String>('getPendingBackupPath');
      if (path != null && path.isNotEmpty) {
        debugPrint('BackupIntentService: Cold-start backup file found: $path');
        return path;
      }
    } catch (e) {
      debugPrint('BackupIntentService error querying initial path: $e');
    }
    return null;
  }

  /// Helper to safely read file bytes from a local file path.
  static Future<Uint8List?> readFileBytes(String path) async {
    if (kIsWeb) return null;
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('BackupIntentService error reading $path: $e');
    }
    return null;
  }

  /// Extracts display name from path.
  static String getFileName(String path) {
    final separator = Platform.pathSeparator;
    if (path.contains(separator)) {
      return path.split(separator).last;
    }
    return path.split('/').last;
  }
}
