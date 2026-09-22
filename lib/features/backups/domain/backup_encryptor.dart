import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'backup_exceptions.dart';

/// Pure Dart cryptographic engine for encrypting and decrypting Spreadlog backup archives.
///
/// Uses AES-256-GCM authenticated encryption with PBKDF2-HMAC-SHA256 key derivation.
class BackupEncryptor {
  static const List<int> magicBytes = [0x53, 0x50, 0x42, 0x4B]; // "SPBK"
  static const int currentFormatVersion = 1;
  static const int saltLength = 16;
  static const int pbkdf2Iterations = 100000;

  final AesGcm _cipher;
  final Pbkdf2 _kdf;
  final Random _secureRandom;

  BackupEncryptor({
    AesGcm? cipher,
    Pbkdf2? kdf,
    Random? secureRandom,
  })  : _cipher = cipher ?? AesGcm.with256bits(),
        _kdf = kdf ??
            Pbkdf2(
              macAlgorithm: Hmac.sha256(),
              iterations: pbkdf2Iterations,
              bits: 256,
            ),
        _secureRandom = secureRandom ?? Random.secure();

  /// Derives a 256-bit SecretKey from [passphrase] and [salt] using PBKDF2.
  Future<SecretKey> deriveKey(String passphrase, List<int> salt) async {
    return _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  /// Encrypts [clearBytes] using [passphrase] into `.spbackup` format.
  Future<Uint8List> encrypt({
    required List<int> clearBytes,
    required String passphrase,
  }) async {
    if (passphrase.isEmpty) {
      throw const InvalidPassphraseException('Passphrase cannot be empty.');
    }

    // 1. Generate 16-byte random salt
    final salt = Uint8List(saltLength);
    for (int i = 0; i < saltLength; i++) {
      salt[i] = _secureRandom.nextInt(256);
    }

    // 2. Derive key
    final secretKey = await deriveKey(passphrase, salt);

    // 3. Encrypt with AES-GCM
    final secretBox = await _cipher.encrypt(
      clearBytes,
      secretKey: secretKey,
    );

    // 4. Pack into .spbackup container format:
    // [4 bytes] Magic "SPBK"
    // [1 byte]  Format Version (1)
    // [1 byte]  Salt Length (16)
    // [16 bytes] Salt
    // [1 byte]  Nonce Length
    // [N bytes] Nonce
    // [1 byte]  Mac Length
    // [M bytes] Mac Tag
    // [Rest]    Ciphertext
    final builder = BytesBuilder(copy: false);
    builder.add(magicBytes);
    builder.addByte(currentFormatVersion);

    builder.addByte(salt.length);
    builder.add(salt);

    builder.addByte(secretBox.nonce.length);
    builder.add(secretBox.nonce);

    builder.addByte(secretBox.mac.bytes.length);
    builder.add(secretBox.mac.bytes);

    builder.add(secretBox.cipherText);

    return builder.takeBytes();
  }

  /// Decrypts [encryptedBytes] using [passphrase].
  ///
  /// Throws [UnsupportedBackupVersionException] if the file format is unrecognised.
  /// Throws [InvalidPassphraseException] or [TamperedBackupException] on authentication failure.
  Future<Uint8List> decrypt({
    required List<int> encryptedBytes,
    required String passphrase,
  }) async {
    if (encryptedBytes.length < magicBytes.length + 5) {
      throw const CorruptedBackupException('File is too short to be a valid backup.');
    }

    final data = Uint8List.fromList(encryptedBytes);
    int offset = 0;

    // Check Magic Header
    for (int i = 0; i < magicBytes.length; i++) {
      if (data[offset++] != magicBytes[i]) {
        throw const UnsupportedBackupVersionException(
          foundVersion: 0,
          supportedVersion: currentFormatVersion,
        );
      }
    }

    // Check Version
    final version = data[offset++];
    if (version != currentFormatVersion) {
      throw UnsupportedBackupVersionException(
        foundVersion: version,
        supportedVersion: currentFormatVersion,
      );
    }

    // Read Salt
    final saltLen = data[offset++];
    if (offset + saltLen > data.length) {
      throw const CorruptedBackupException('Truncated salt in backup header.');
    }
    final salt = data.sublist(offset, offset + saltLen);
    offset += saltLen;

    // Read Nonce
    final nonceLen = data[offset++];
    if (offset + nonceLen > data.length) {
      throw const CorruptedBackupException('Truncated nonce in backup header.');
    }
    final nonce = data.sublist(offset, offset + nonceLen);
    offset += nonceLen;

    // Read MAC
    final macLen = data[offset++];
    if (offset + macLen > data.length) {
      throw const CorruptedBackupException('Truncated MAC in backup header.');
    }
    final macBytes = data.sublist(offset, offset + macLen);
    offset += macLen;

    // Ciphertext
    final cipherText = data.sublist(offset);

    // Derive Key
    final secretKey = await deriveKey(passphrase, salt);

    // Reconstruct SecretBox
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    // Decrypt
    try {
      final decrypted = await _cipher.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return Uint8List.fromList(decrypted);
    } on SecretBoxAuthenticationError {
      throw const InvalidPassphraseException(
        'Decryption failed. The passphrase may be incorrect or the backup file has been tampered with.',
      );
    } catch (e) {
      throw TamperedBackupException('Decryption error: $e');
    }
  }
}
