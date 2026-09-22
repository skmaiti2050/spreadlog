import 'dart:convert';
import 'dart:typed_data';

import 'package:aviation_logbook/features/backups/domain/backup_encryptor.dart';
import 'package:aviation_logbook/features/backups/domain/backup_exceptions.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupEncryptor Pure Dart Cryptography', () {
    late BackupEncryptor fastEncryptor;

    setUp(() {
      // Use 1,000 iterations in unit test for fast execution
      fastEncryptor = BackupEncryptor(
        kdf: Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: 1000,
          bits: 256,
        ),
      );
    });

    test('encrypts and decrypts roundtrip successfully', () async {
      final original = utf8.encode('Top Secret Pilot Logbook Flight Data 2026!');
      const passphrase = 'SuperSafePassphrase123!#';

      final encrypted = await fastEncryptor.encrypt(
        clearBytes: original,
        passphrase: passphrase,
      );

      // Verify header format
      expect(encrypted.length, greaterThan(BackupEncryptor.magicBytes.length + 30));
      expect(encrypted.sublist(0, 4), equals(BackupEncryptor.magicBytes));
      expect(encrypted[4], equals(BackupEncryptor.currentFormatVersion));

      // Decrypt
      final decrypted = await fastEncryptor.decrypt(
        encryptedBytes: encrypted,
        passphrase: passphrase,
      );

      expect(decrypted, equals(original));
      expect(utf8.decode(decrypted), equals('Top Secret Pilot Logbook Flight Data 2026!'));
    });

    test('fails decryption when given incorrect passphrase', () async {
      final original = utf8.encode('Sensitive records');
      const correctPass = 'CorrectPassphrase';
      const wrongPass = 'IncorrectPassphrase';

      final encrypted = await fastEncryptor.encrypt(
        clearBytes: original,
        passphrase: correctPass,
      );

      expect(
        () async => await fastEncryptor.decrypt(
          encryptedBytes: encrypted,
          passphrase: wrongPass,
        ),
        throwsA(isA<InvalidPassphraseException>()),
      );
    });

    test('fails decryption when ciphertext is tampered with', () async {
      final original = utf8.encode('Unmodified flight data');
      const passphrase = 'Passphrase';

      final encrypted = await fastEncryptor.encrypt(
        clearBytes: original,
        passphrase: passphrase,
      );

      // Flip a bit in the ciphertext payload
      final tampered = Uint8List.fromList(encrypted);
      tampered[tampered.length - 1] ^= 0xFF;

      expect(
        () async => await fastEncryptor.decrypt(
          encryptedBytes: tampered,
          passphrase: passphrase,
        ),
        throwsA(anyOf(isA<InvalidPassphraseException>(), isA<TamperedBackupException>())),
      );
    });

    test('fails decryption when magic header is invalid', () async {
      final original = utf8.encode('Data');
      const passphrase = 'Pass';

      final encrypted = await fastEncryptor.encrypt(
        clearBytes: original,
        passphrase: passphrase,
      );

      final corruptedHeader = Uint8List.fromList(encrypted);
      corruptedHeader[0] = 0x00; // Corrupt 'S' in 'SPBK'

      expect(
        () async => await fastEncryptor.decrypt(
          encryptedBytes: corruptedHeader,
          passphrase: passphrase,
        ),
        throwsA(isA<UnsupportedBackupVersionException>()),
      );
    });

    test('throws InvalidPassphraseException when encrypting with empty passphrase', () async {
      final original = utf8.encode('Data');

      expect(
        () async => await fastEncryptor.encrypt(
          clearBytes: original,
          passphrase: '',
        ),
        throwsA(isA<InvalidPassphraseException>()),
      );
    });
  });
}
