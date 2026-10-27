import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';

/// Service responsible for managing Google OAuth authentication for Drive & Gmail APIs.
///
/// google_sign_in 7 splits sign-in (who the user is) from authorization
/// (access tokens for scopes) and no longer tracks the current user, so this
/// service keeps that state and exposes the same API the screens used before.
class GoogleAuthService {
  /// Restricted scope allowing sending emails solely to the authenticated user's own inbox.
  static const String gmailSendSelfScope =
      'https://www.googleapis.com/auth/gmail.send.self';

  static const List<String> defaultScopes = [
    drive.DriveApi.driveFileScope,
    gmailSendSelfScope,
  ];

  /// Web OAuth client from Google Cloud Console. The web build signs in with
  /// it directly; Android passes it as the server client ID, which Credential
  /// Manager requires when there is no google-services.json.
  static const String webClientId =
      '200978100975-hp3kmikut8rpn9prvv973u9p66s2238g.apps.googleusercontent.com';

  // GoogleSignIn.instance is a singleton that must be initialized exactly
  // once per isolate, however many services are created.
  static Future<void>? _initialization;

  final GoogleSignIn _googleSignIn;
  final _userChanges = StreamController<GoogleSignInAccount?>.broadcast();
  StreamSubscription<GoogleSignInAuthenticationEvent>? _eventsSub;
  GoogleSignInAccount? _currentUser;

  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> _ensureInitialized() async {
    _initialization ??= _googleSignIn.initialize(
      clientId: kIsWeb ? webClientId : null,
      serverClientId: kIsWeb ? null : webClientId,
    );
    try {
      await _initialization;
    } catch (_) {
      // Allow a later call to retry, e.g. after a transient platform error.
      _initialization = null;
      rethrow;
    }
    _eventsSub ??= _googleSignIn.authenticationEvents.listen(
      (event) => _setUser(switch (event) {
        GoogleSignInAuthenticationEventSignIn(:final user) => user,
        GoogleSignInAuthenticationEventSignOut() => null,
      }),
      onError: (Object e) => debugPrint('Google auth event error: $e'),
    );
  }

  void _setUser(GoogleSignInAccount? user) {
    if (user == _currentUser) return;
    _currentUser = user;
    _userChanges.add(user);
  }

  /// Current signed-in user, if any.
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Whether a Google user is actively signed in.
  bool get isSignedIn => _currentUser != null;

  /// Stream of user sign-in state changes.
  Stream<GoogleSignInAccount?> get onCurrentUserChanged => _userChanges.stream;

  /// Interactive sign in flow.
  ///
  /// On web, sign-in goes through the button rendered by Google Identity
  /// Services instead (see google_sign_in_button_web.dart); this only retries
  /// the lightweight flow there.
  Future<GoogleSignInAccount?> signIn() async {
    await _ensureInitialized();
    if (!_googleSignIn.supportsAuthenticate()) {
      return signInSilently();
    }
    final account = await _googleSignIn.authenticate(scopeHint: defaultScopes);
    _setUser(account);
    // Scopes are no longer granted at sign-in; ask while we still have the
    // user's tap, so backups work without a separate "Authorize" step.
    try {
      await account.authorizationClient.authorizeScopes(defaultScopes);
    } on GoogleSignInException catch (e) {
      debugPrint('Google scope authorization skipped: ${e.code}');
    }
    return account;
  }

  /// Checks whether required scopes are authorized without showing any UI or popups.
  Future<bool> canAccessScopes() async {
    try {
      final user = _currentUser;
      if (user == null) return false;
      final authorization =
          await user.authorizationClient.authorizationForScopes(defaultScopes);
      return authorization != null;
    } catch (e) {
      debugPrint('canAccessScopes check error: $e');
      return false;
    }
  }

  /// Explicitly requests Drive and Gmail scopes via user-gesture popup.
  Future<bool> requestScopes() async {
    try {
      final user = _currentUser;
      if (user == null) return false;
      await user.authorizationClient.authorizeScopes(defaultScopes);
      return true;
    } catch (e) {
      debugPrint('requestScopes error: $e');
      return false;
    }
  }

  /// Silent sign in flow (ideal for app startup and background sync).
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      await _ensureInitialized();
      // Some platforms (web) report the result only through
      // authenticationEvents and return null here.
      final account = await _googleSignIn.attemptLightweightAuthentication();
      if (account != null) _setUser(account);
      return account ?? _currentUser;
    } catch (e) {
      debugPrint('Google Silent Sign-In skipped: $e');
      return null;
    }
  }

  /// Disconnects and signs out the current Google session.
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    } finally {
      _setUser(null);
    }
  }

  /// Stops listening for sign-in events.
  Future<void> dispose() async {
    await _eventsSub?.cancel();
    await _userChanges.close();
  }

  /// Obtains an authenticated HTTP client for Google APIs (Drive, Gmail).
  ///
  /// Returns null when nobody is signed in or the scopes haven't been granted;
  /// granting them needs a user gesture ([requestScopes]).
  Future<AuthClient?> getAuthenticatedClient() async {
    try {
      final user = _currentUser ?? await signInSilently();
      if (user == null) {
        debugPrint('getAuthenticatedClient: No user logged in');
        return null;
      }
      final authorization =
          await user.authorizationClient.authorizationForScopes(defaultScopes);
      if (authorization == null) {
        debugPrint('getAuthenticatedClient: Scopes not yet authorized');
        return null;
      }
      return authorization.authClient(scopes: defaultScopes);
    } catch (e) {
      debugPrint('Failed to obtain authenticated client: $e');
      return null;
    }
  }
}
