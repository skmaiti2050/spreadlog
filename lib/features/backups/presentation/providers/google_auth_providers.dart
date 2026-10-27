import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/google_auth_service.dart';
import '../../data/transports/gmail_backup_transport.dart';
import '../../data/transports/google_drive_backup_transport.dart';

/// Provider for the singleton GoogleAuthService instance.
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  final service = GoogleAuthService();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream provider listening to the real-time Google Sign-In account changes.
final googleUserStreamProvider = StreamProvider<GoogleSignInAccount?>((ref) {
  final authService = ref.watch(googleAuthServiceProvider);
  return authService.onCurrentUserChanged;
});

/// Provider supplying the GoogleDriveBackupTransport.
final googleDriveTransportProvider = Provider<GoogleDriveBackupTransport>((ref) {
  final authService = ref.watch(googleAuthServiceProvider);
  return GoogleDriveBackupTransport(authService);
});

/// Provider supplying the GmailBackupTransport.
final gmailTransportProvider = Provider<GmailBackupTransport>((ref) {
  final authService = ref.watch(googleAuthServiceProvider);
  final driveTransport = ref.watch(googleDriveTransportProvider);
  return GmailBackupTransport(authService, driveTransport);
});
