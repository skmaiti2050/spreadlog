import 'package:aviation_logbook/features/backups/data/google_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Minimal GoogleSignIn stand-in: counts initialize() calls and lets each test
/// choose what authenticate() does.
class _FakeGoogleSignIn implements GoogleSignIn {
  _FakeGoogleSignIn({required this.authenticateError});

  final Object authenticateError;
  int initializeCalls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #initialize:
        initializeCalls++;
        return Future<void>.value();
      case #authenticationEvents:
        return const Stream<GoogleSignInAuthenticationEvent>.empty();
      case #supportsAuthenticate:
        return true;
      case #authenticate:
        return Future<GoogleSignInAccount>.error(authenticateError);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('GoogleAuthService', () {
    test('signIn returns null when the user closes the account picker',
        () async {
      final service = GoogleAuthService(
        googleSignIn: _FakeGoogleSignIn(
          authenticateError: const GoogleSignInException(
            code: GoogleSignInExceptionCode.canceled,
          ),
        ),
      );

      expect(await service.signIn(), isNull);
      expect(service.isSignedIn, isFalse);
    });

    test('signIn still reports real sign-in failures', () async {
      final service = GoogleAuthService(
        googleSignIn: _FakeGoogleSignIn(
          authenticateError: const GoogleSignInException(
            code: GoogleSignInExceptionCode.clientConfigurationError,
          ),
        ),
      );

      await expectLater(
        service.signIn(),
        throwsA(isA<GoogleSignInException>()),
      );
    });

    test('initializes each GoogleSignIn exactly once', () async {
      const error = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
      final first = _FakeGoogleSignIn(authenticateError: error);
      final second = _FakeGoogleSignIn(authenticateError: error);

      await GoogleAuthService(googleSignIn: first).signIn();
      await GoogleAuthService(googleSignIn: first).signIn();
      await GoogleAuthService(googleSignIn: second).signIn();

      expect(first.initializeCalls, 1);
      expect(second.initializeCalls, 1);
    });
  });
}
