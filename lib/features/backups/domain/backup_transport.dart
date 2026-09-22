import 'dart:typed_data';

/// Abstract port for pluggable backup delivery mechanisms.
abstract class BackupTransport {
  /// The user-facing name of this transport (e.g. 'OS Share / Export', 'SMTP Email').
  String get name;

  /// Dispatches the [encryptedBytes] named [suggestedFileName] to the destination.
  Future<void> dispatchBackup({
    required Uint8List encryptedBytes,
    required String suggestedFileName,
    String? recipientEmail,
  });
}
