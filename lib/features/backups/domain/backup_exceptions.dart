/// Pure Dart exceptions related to backup encryption, packaging, and restoration.
library;

class BackupException implements Exception {
  final String message;
  final dynamic cause;

  const BackupException(this.message, [this.cause]);

  @override
  String toString() => cause != null ? 'BackupException: $message ($cause)' : 'BackupException: $message';
}

class InvalidPassphraseException extends BackupException {
  const InvalidPassphraseException([super.message = 'The provided passphrase is incorrect or decryption failed.']);
}

class TamperedBackupException extends BackupException {
  const TamperedBackupException([super.message = 'The backup archive has been tampered with or corrupted (MAC tag verification failed).']);
}

class CorruptedBackupException extends BackupException {
  final String? failedFile;

  const CorruptedBackupException(super.message, {this.failedFile});
}

class UnsupportedBackupVersionException extends BackupException {
  final int foundVersion;
  final int supportedVersion;

  const UnsupportedBackupVersionException({
    required this.foundVersion,
    required this.supportedVersion,
  }) : super('Unsupported backup archive format version: $foundVersion (current: $supportedVersion)');
}

class BackupTransportException extends BackupException {
  const BackupTransportException(super.message, [super.cause]);
}
