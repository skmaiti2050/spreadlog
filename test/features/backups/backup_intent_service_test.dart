import 'package:aviation_logbook/features/backups/data/backup_intent_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.spreadlog.app/backup_intent');

  group('BackupIntentService Tests', () {
    test('getFileName extracts name from Unix and Windows path strings', () {
      expect(
        BackupIntentService.getFileName('/storage/emulated/0/Download/flight_backup.spbackup'),
        equals('flight_backup.spbackup'),
      );
      expect(
        BackupIntentService.getFileName('flight_backup.spreadlog'),
        equals('flight_backup.spreadlog'),
      );
    });

    test('getPendingBackupPath queries channel and returns path', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getPendingBackupPath') {
          return '/data/user/0/com.spreadlog.app/cache/test.spbackup';
        }
        return null;
      });

      final path = await BackupIntentService.getPendingBackupPath();
      expect(path, equals('/data/user/0/com.spreadlog.app/cache/test.spbackup'));
    });

    test('onBackupFileReceived receives path emitted by method channel', () async {
      String? callbackPath;
      BackupIntentService.initialize(onFileReceived: (p) => callbackPath = p);

      final futureEmission = BackupIntentService.onBackupFileReceived.first;

      // Simulate native platform sending an incoming file intent
      const codec = StandardMethodCodec();
      final byteData = codec.encodeMethodCall(
        const MethodCall('onBackupFileReceived', '/data/user/0/cache/warm_start.spbackup'),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('com.spreadlog.app/backup_intent', byteData, (_) {});

      final receivedPath = await futureEmission;
      expect(receivedPath, equals('/data/user/0/cache/warm_start.spbackup'));
      expect(callbackPath, equals('/data/user/0/cache/warm_start.spbackup'));
    });
  });
}
