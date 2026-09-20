import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aviation_logbook/features/endorsements/domain/document_hasher.dart';

void main() {
  group('DocumentHasher Tests', () {
    late DocumentHasher hasher;

    setUp(() {
      hasher = DocumentHasher();
    });

    test('Computes correct SHA-256 for standard test string', () async {
      // Standard NIST test vector for "hello world"
      // SHA-256("hello world") = b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9
      final bytes = Uint8List.fromList(utf8.encode('hello world'));
      final hash = await hasher.computeSha256(bytes);
      expect(hash, 'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9');
    });

    test('verifySha256 returns true for matching hash and false for tampered bytes', () async {
      final original = Uint8List.fromList(utf8.encode('SACAA Flight Instructor Endorsement CAR 61.01.5'));
      final hash = await hasher.computeSha256(original);

      final isOriginalValid = await hasher.verifySha256(original, hash);
      expect(isOriginalValid, isTrue);

      final tampered = Uint8List.fromList(utf8.encode('SACAA Flight Instructor Endorsement CAR 61.01.5 - TAMPERED'));
      final isTamperedValid = await hasher.verifySha256(tampered, hash);
      expect(isTamperedValid, isFalse);
    });

    test('Empty bytes produces standard empty SHA-256', () async {
      final bytes = Uint8List(0);
      final hash = await hasher.computeSha256(bytes);
      // SHA-256 of empty string is e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      expect(hash, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    });
  });
}

