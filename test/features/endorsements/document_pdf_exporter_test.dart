import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aviation_logbook/features/endorsements/data/document_pdf_exporter.dart';
import 'package:aviation_logbook/features/endorsements/data/document_storage/document_file_storage_web.dart';
import 'package:aviation_logbook/features/endorsements/domain/document_hasher.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_category.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_document.dart';
import 'package:aviation_logbook/features/endorsements/domain/endorsement_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'endorsements_repository_test.dart' show InMemoryDocumentFileStorage;

void main() {
  final portrait = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAABgAAAAwCAIAAACE6i30AAAAKUlEQVR4nO3MMQ0AAAwDoMqpf4ObiZ4k3OTaiYhEIpFIJBKJRCKRaBk9Jg3jzIptzqgAAAAASUVORK5CYII=',
  );
  final landscape = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAADAAAAAYCAIAAAAzn+mLAAAAMUlEQVR4nO3OQQ0AMAgEMOQgAv+2NhccjyYV0Op5p1R8ICQkJJQeCAkJCaUHQkJCyz7EMD3bvmCYxAAAAABJRU5ErkJggg==',
  );
  late InMemoryDocumentFileStorage storage;
  late EndorsementDocument document;
  setUp(() async {
    storage = InMemoryDocumentFileStorage();
    storage.storage['memory://portrait'] = portrait;
    storage.storage['memory://landscape'] = landscape;
    final hasher = DocumentHasher();
    final pages = [
      EndorsementPage(
        originalPath: 'memory://portrait',
        sha256: await hasher.computeSha256(portrait),
      ),
      EndorsementPage(
        originalPath: 'memory://landscape',
        sha256: await hasher.computeSha256(landscape),
      ),
    ];
    document = EndorsementDocument(
      id: 'export',
      category: EndorsementCategory.tw,
      endorsementDate: DateTime(2026),
      capturedAt: DateTime(2026),
      originalPath: pages.first.originalPath,
      sha256: pages.first.sha256,
      storedPages: pages,
      documentHash: await hasher.computeDocumentHash(
        pages.map((p) => p.sha256).toList(),
      ),
    );
  });
  test('exports all pages in order with portrait and landscape sheets, retaining originals', () async {
    final bytes = await DocumentPdfExporter(storage: storage).export(document);
    final pdf = latin1.decode(bytes);
    expect(pdf, startsWith('%PDF'));
    expect(RegExp(r'/Type\s*/Page\b').allMatches(pdf), hasLength(2));
    final sizes = RegExp(r'/MediaBox\s*\[([^\]]+)\]')
        .allMatches(pdf)
        .map(
          (m) => m[1]!.trim().split(RegExp(r'\s+')).map(double.parse).toList(),
        )
        .toList();
    expect(sizes, hasLength(2));
    expect(sizes[0][2], lessThan(sizes[0][3]));
    expect(sizes[1][2], greaterThan(sizes[1][3]));
    expect(storage.storage['memory://portrait'], portrait);
    expect(storage.storage['memory://landscape'], landscape);
    final fixture = File('build/test-artifacts/grouped-document.pdf');
    await fixture.parent.create(recursive: true);
    await fixture.writeAsBytes(bytes);
  });
  test('refuses a missing page rather than producing a partial PDF', () async {
    storage.storage.remove('memory://landscape');
    await expectLater(
      DocumentPdfExporter(storage: storage).export(document),
      throwsStateError,
    );
  });
  test('refuses a corrupted later page', () async {
    storage.storage['memory://landscape'] = [1, 2];
    await expectLater(
      DocumentPdfExporter(storage: storage).export(document),
      throwsStateError,
    );
  });
  test('refuses a reordered page manifest', () async {
    await expectLater(
      DocumentPdfExporter(storage: storage).export(
        document.copyWith(storedPages: document.pages.reversed.toList()),
      ),
      throwsStateError,
    );
  });
  test('exports a legacy single page', () async {
    final legacy = EndorsementDocument(
      id: 'legacy',
      category: document.category,
      endorsementDate: document.endorsementDate,
      capturedAt: document.capturedAt,
      originalPath: document.originalPath,
      sha256: document.sha256,
    );
    final bytes = await DocumentPdfExporter(storage: storage).export(legacy);
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)),
      hasLength(1),
    );
  });
  test('exports browser data-URI pages through web storage', () async {
    final webStorage = WebDocumentFileStorage();
    final pages = <EndorsementPage>[];
    for (var i = 0; i < document.pageCount; i++) {
      final bytes = Uint8List.fromList(
        storage.storage[document.pages[i].originalPath]!,
      );
      final path = await webStorage.saveDocumentFile(
        id: '$i',
        fileExtension: 'png',
        bytes: bytes,
      );
      pages.add(
        EndorsementPage(originalPath: path, sha256: document.pages[i].sha256),
      );
    }
    final bytes = await DocumentPdfExporter(storage: webStorage).export(
      document.copyWith(
        storedPages: pages,
        originalPath: pages.first.originalPath,
      ),
    );
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)),
      hasLength(2),
    );
  });
}
