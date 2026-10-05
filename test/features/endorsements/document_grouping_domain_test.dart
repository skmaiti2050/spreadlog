import 'package:aviation_logbook/features/endorsements/domain/document_hasher.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_category.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_document.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ordered fingerprint detects order, missing and duplicated pages',
    () async {
      final hasher = DocumentHasher();
      final hash = await hasher.computeDocumentHash(['a', 'b']);
      expect(await hasher.computeDocumentHash(['a', 'b']), hash);
      expect(await hasher.computeDocumentHash(['b', 'a']), isNot(hash));
      expect(await hasher.computeDocumentHash(['a']), isNot(hash));
      expect(await hasher.computeDocumentHash(['a', 'b', 'b']), isNot(hash));
    },
  );
  test('page inputs and document pages are immutable snapshots with a portable JSON roundtrip', () {
    final bytes = [1, 2];
    final input = DocumentPageInput(imageBytes: bytes, fileExtension: 'jpg');
    bytes.clear();
    expect(input.imageBytes, [1, 2]);
    final pages = [
      const EndorsementPage(
        originalPath: 'first.jpg',
        sha256: 'a',
        pageNumber: 42,
      ),
      const EndorsementPage(originalPath: 'second.jpg', sha256: 'b'),
    ];
    final doc = EndorsementDocument(
      id: 'doc',
      category: EndorsementCategory.tw,
      endorsementDate: DateTime(2026),
      capturedAt: DateTime(2026),
      originalPath: 'first.jpg',
      sha256: 'a',
      storedPages: pages,
      documentHash: 'group',
    );
    pages.clear();
    expect(doc.pageCount, 2);
    expect(doc.pages.map((p) => p.pageNumber), [42, null]);
    expect(() => doc.pages.clear(), throwsUnsupportedError);
    expect(EndorsementDocument.fromJson(doc.toJson()), doc);
  });
}
