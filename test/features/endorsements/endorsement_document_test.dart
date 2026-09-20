import 'package:flutter_test/flutter_test.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_category.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_document.dart';

void main() {
  group('EndorsementDocument Domain Tests', () {
    final now = DateTime(2026, 9, 20, 10, 30);
    final docDate = DateTime(2026, 9, 15);

    test('Initializes with correct immutability defaults', () {
      final doc = EndorsementDocument(
        id: 'doc-1',
        category: EndorsementCategory.nightRating,
        endorsementDate: docDate,
        pageNumber: 12,
        originalPath: 'endorsements/doc-1/original.jpg',
        sha256: 'abc123hash',
        capturedAt: now,
        notes: 'Night Rating signed by DE',
      );

      expect(doc.id, 'doc-1');
      expect(doc.category, EndorsementCategory.nightRating);
      expect(doc.endorsementDate, docDate);
      expect(doc.pageNumber, 12);
      expect(doc.originalPath, 'endorsements/doc-1/original.jpg');
      expect(doc.sha256, 'abc123hash');
      expect(doc.isSuperseded, isFalse);
      expect(doc.isReplacement, isFalse);
      expect(doc.notes, 'Night Rating signed by DE');
    });

    test('isSuperseded returns true when supersededBy is populated', () {
      final original = EndorsementDocument(
        id: 'doc-1',
        category: EndorsementCategory.vp,
        endorsementDate: docDate,
        originalPath: 'endorsements/doc-1/original.jpg',
        sha256: 'hash1',
        capturedAt: now,
        supersededBy: 'doc-2',
      );

      expect(original.isSuperseded, isTrue);
      expect(original.supersededBy, 'doc-2');
    });

    test('isReplacement returns true when supersedes is populated', () {
      final replacement = EndorsementDocument(
        id: 'doc-2',
        category: EndorsementCategory.vp,
        endorsementDate: docDate,
        originalPath: 'endorsements/doc-2/original.jpg',
        sha256: 'hash2',
        capturedAt: now,
        supersedes: 'doc-1',
      );

      expect(replacement.isReplacement, isTrue);
      expect(replacement.supersedes, 'doc-1');
    });

    test('JSON serialization roundtrip preserves all attributes', () {
      final doc = EndorsementDocument(
        id: 'doc-99',
        category: EndorsementCategory.instrumentRating,
        endorsementDate: docDate,
        pageNumber: 4,
        originalPath: 'endorsements/doc-99/original.jpg',
        processedPath: 'endorsements/doc-99/processed.webp',
        thumbnailPath: 'endorsements/doc-99/thumbnail.webp',
        sha256: 'deadbeef99',
        capturedAt: now,
        supersededBy: 'doc-100',
        supersedes: 'doc-98',
        notes: 'Annual IF renewal',
      );

      final json = doc.toJson();
      final revived = EndorsementDocument.fromJson(json);

      expect(revived, equals(doc));
    });

    test('EndorsementCategory fromCode parses known codes correctly and defaults gracefully', () {
      expect(EndorsementCategory.fromCode('VP'), EndorsementCategory.vp);
      expect(EndorsementCategory.fromCode('RU'), EndorsementCategory.ru);
      expect(EndorsementCategory.fromCode('NIGHT'), EndorsementCategory.nightRating);
      expect(EndorsementCategory.fromCode('IFR'), EndorsementCategory.instrumentRating);
      expect(EndorsementCategory.fromCode('MODEL_REGISTER'), EndorsementCategory.modelRegister);
      expect(EndorsementCategory.fromCode('UNKNOWN_CODE'), EndorsementCategory.other);
    });
  });
}

