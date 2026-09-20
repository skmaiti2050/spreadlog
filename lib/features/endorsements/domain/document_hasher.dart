import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Pure Dart cryptographic utility for calculating SHA-256 tamper-evident checksums.
class DocumentHasher {
  final HashAlgorithm _algorithm;

  DocumentHasher({HashAlgorithm? algorithm}) : _algorithm = algorithm ?? Sha256();

  /// Computes a hexadecimal SHA-256 digest of [bytes].
  Future<String> computeSha256(Uint8List bytes) async {
    final hash = await _algorithm.hash(bytes);
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Verifies whether [bytes] produces the expected [expectedHash] (case-insensitive).
  Future<bool> verifySha256(Uint8List bytes, String expectedHash) async {
    final calculated = await computeSha256(bytes);
    return calculated.toLowerCase() == expectedHash.trim().toLowerCase();
  }
}

