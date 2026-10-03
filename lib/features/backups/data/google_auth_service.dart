import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';

/// Service responsible for managing Google OAuth authentication for Drive & Gmail APIs.
class GoogleAuthService {
  /// Restricted scope allowing sending emails solely to the authenticated user's own inbox.
  static const String gmailSendSelfScope =
      'https://www.googleapis.com/auth/gmail.send.self';

  static const List<String> defaultScopes = [
    drive.DriveApi.driveFileScope,
    gmailSendSelfScope,
  ];

  /// Client ID configured for web deployment in Google Cloud Console.
  static const String webClientId =
      '200978100975-hp3kmikut8rpn9prvv973u9p66s2238g.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn;

  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: kIsWeb ? webClientId : null,
              scopes: defaultScopes,
            );

  /// Current signed-in user, if any.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Whether a Google user is actively signed in.
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Stream of user sign-in state changes.
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  /// Interactive sign in flow.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      var account = await _googleSignIn.signIn();
      account ??= _googleSignIn.currentUser;
      if (account != null && kIsWeb) {
        await ensureScopes();
      }
      return account;
    } catch (e) {
      debugPrint('Google Sign-In note: $e');
      // If popup_closed or dismissed, check if user was resolved (e.g. via One Tap)
      final existingUser = _googleSignIn.currentUser;
      if (existingUser != null) {
        if (kIsWeb) {
          try {
            await ensureScopes();
          } catch (_) {}
        }
        return existingUser;
      }
      rethrow;
    }
  }

  /// Ensures required OAuth scopes (Drive, Gmail) are granted on Web.
  Future<bool> ensureScopes() async {
    try {
      final hasAccess = await _googleSignIn.canAccessScopes(defaultScopes);
      if (hasAccess) return true;
      return await _googleSignIn.requestScopes(defaultScopes);
    } catch (e) {
      debugPrint('Error ensuring scopes: $e');
      return false;
    }
  }

  /// Silent sign in flow (ideal for app startup and background sync).
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      return account;
    } catch (e) {
      debugPrint('Google Silent Sign-In skipped: $e');
      return null;
    }
  }

  /// Disconnects and signs out the current Google session.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    }
  }

  /// Obtains an authenticated HTTP client for Google APIs (Drive, Gmail).
  Future<AuthClient?> getAuthenticatedClient() async {
    try {
      var user = _googleSignIn.currentUser;
      user ??= await signInSilently();
      if (user == null) {
        debugPrint('getAuthenticatedClient: No user logged in');
        return null;
      }

      // On Web, Google Identity Services (GIS) requires requesting scopes to generate accessToken
      if (kIsWeb) {
        final hasAccess = await _googleSignIn.canAccessScopes(defaultScopes);
        if (!hasAccess) {
          final granted = await _googleSignIn.requestScopes(defaultScopes);
          if (!granted) {
            debugPrint('OAuth scopes not granted by user on web');
            return null;
          }
        }
      }

      return await _googleSignIn.authenticatedClient();
    } catch (e) {
      debugPrint('Failed to obtain authenticated client: $e');
      return null;
    }
  }
}
