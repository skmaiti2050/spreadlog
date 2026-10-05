import 'package:aviation_logbook/features/endorsements/data/scanner/document_scanner_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.spreadlog.app/scanner');
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test('automatic scanning preserves every returned page', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'scanAutomatic');
          return ['first.jpg', 'second.jpg'];
        });
    expect(await const DocumentScannerAdapter().getScannedImagePaths(), [
      'first.jpg',
      'second.jpg',
    ]);
  });
  test('initialization failure is reported and never silently opens manual scanning', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          throw PlatformException(
            code: 'SCANNER_UNAVAILABLE',
            message: 'Module download failed',
          );
        });
    await expectLater(
      const DocumentScannerAdapter().getScannedImagePaths(),
      throwsA(isA<PlatformException>()),
    );
    expect(calls, ['scanAutomatic']);
  });
  test('manual scanner launches only on explicit request', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'scanManual');
          return <String>[];
        });
    expect(
      await const DocumentScannerAdapter().getScannedImagePaths(manual: true),
      isEmpty,
    );
  });
}
