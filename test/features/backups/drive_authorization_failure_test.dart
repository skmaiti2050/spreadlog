import 'dart:typed_data';

import 'package:aviation_logbook/features/backups/data/google_auth_service.dart';
import 'package:aviation_logbook/features/backups/data/transports/google_drive_backup_transport.dart';
import 'package:aviation_logbook/features/backups/domain/backup_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

class _Client extends http.BaseClient implements AuthClient {
  final int status;
  bool closed = false;
  _Client(this.status);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(
          Uint8List.fromList(
            '{"error":{"code":$status,"message":"Denied"}}'.codeUnits,
          ),
        ),
        status,
        headers: {'content-type': 'application/json'},
      );
  @override
  void close() {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements GoogleAuthService {
  final _Client client;
  bool invalidated = false;
  _Auth(this.client);
  @override
  Future<AuthClient?> getAuthenticatedClient() async => client;
  @override
  Future<void> invalidateAuthorization() async {
    invalidated = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    '401 wrapped by folder lookup invalidates access and requests reconnect',
    () async {
      final client = _Client(401);
      final auth = _Auth(client);
      await expectLater(
        GoogleDriveBackupTransport(auth).dispatchBackup(
          encryptedBytes: Uint8List.fromList([1]),
          suggestedFileName: 'test.spbackup',
        ),
        throwsA(isA<BackupAuthorizationException>()),
      );
      expect(auth.invalidated, isTrue);
      expect(client.closed, isTrue);
    },
  );

  test(
    'server failures close the client without invalidating authorization',
    () async {
      final client = _Client(500);
      final auth = _Auth(client);
      await expectLater(
        GoogleDriveBackupTransport(auth).listBackups(),
        throwsA(isA<BackupTransportException>()),
      );
      expect(auth.invalidated, isFalse);
      expect(client.closed, isTrue);
    },
  );
}
