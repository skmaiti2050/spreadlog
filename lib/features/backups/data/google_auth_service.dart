import 'dart:async';
import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/oauth2/v2.dart' as oauth2;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Google account the app backs up to.
@immutable
class GoogleUser {
  final String id;
  final String email;
  final String? displayName;

  const GoogleUser({required this.id, required this.email, this.displayName});

  GoogleUser.fromIdentity(GoogleIdentity identity)
    : this(
        id: identity.id,
        email: identity.email,
        displayName: identity.displayName,
      );

  factory GoogleUser.fromJson(Map<String, dynamic> json) => GoogleUser(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
  };

  @override
  bool operator ==(Object other) =>
      other is GoogleUser &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(id, email, displayName);
}

/// Service responsible for managing Google OAuth authentication for Drive & Gmail APIs.
///
/// google_sign_in 7 splits sign-in (who the user is) from authorization
/// (access tokens for scopes) and no longer tracks the current user.
///
/// Every platform signs in interactively once, remembers the account, and
/// afterwards only asks for access tokens:
/// - Android: "lightweight" sign-in goes through Credential Manager, which
///   shows a "Signing in as…" sheet and needs a foreground activity. Token
///   requests are silent once the scopes are granted, also from the
///   background backup task.
/// - Web: sign-in alone grants no API access, and a token popup must come
///   straight from a click. So "Sign in" is one token request for the API
///   scopes plus the basic profile, and the profile comes from userinfo.
///   Tokens last an hour and don't survive a reload; reconnecting is one
///   click, and the popup closes itself once access was granted before.
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

  /// Web sign-in asks for the API scopes and the profile in one popup.
  static const List<String> _webSignInScopes = [
    ...defaultScopes,
    oauth2.Oauth2Api.openidScope,
    oauth2.Oauth2Api.userinfoEmailScope,
    oauth2.Oauth2Api.userinfoProfileScope,
  ];

  static const String _prefSignedInUser = 'google_signed_in_user';

  // GoogleSignIn.instance is a singleton that must be initialized exactly
  // once per isolate, however many services are created; keyed by instance
  // so an injected GoogleSignIn gets its own initialization.
  static final _initializations = Expando<Future<void>>();

  final GoogleSignIn _googleSignIn;
  final _userChanges = StreamController<GoogleUser?>.broadcast();
  StreamSubscription<GoogleSignInAuthenticationEvent>? _eventsSub;
  GoogleUser? _currentUser;

  GoogleAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> _ensureInitialized() async {
    final initialization = _initializations[_googleSignIn] ??= _googleSignIn
        .initialize(
          clientId: kIsWeb ? webClientId : null,
          serverClientId: kIsWeb ? null : webClientId,
        );
    try {
      await initialization;
    } catch (_) {
      // Allow a later call to retry, e.g. after a transient platform error.
      _initializations[_googleSignIn] = null;
      rethrow;
    }
    _eventsSub ??= _googleSignIn.authenticationEvents.listen(
      (event) => _setUser(switch (event) {
        GoogleSignInAuthenticationEventSignIn(:final user) =>
          GoogleUser.fromIdentity(user),
        GoogleSignInAuthenticationEventSignOut() => null,
      }),
      onError: (Object e) => debugPrint('Google auth event error: $e'),
    );
  }

  void _setUser(GoogleUser? user) {
    // A sign-in can finish after dispose(); the stream is closed by then.
    if (user == _currentUser || _userChanges.isClosed) return;
    _currentUser = user;
    _userChanges.add(user);
  }

  Future<void> _saveUser(GoogleUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_prefSignedInUser);
    } else {
      await prefs.setString(_prefSignedInUser, jsonEncode(user.toJson()));
    }
  }

  Future<GoogleUser?> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefSignedInUser);
    if (json == null) return null;
    try {
      return GoogleUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Ignoring unreadable saved Google account: $e');
      return null;
    }
  }

  /// Current signed-in user, if any.
  GoogleUser? get currentUser => _currentUser;

  /// Whether a Google user is actively signed in.
  bool get isSignedIn => _currentUser != null;

  /// Stream of user sign-in state changes.
  Stream<GoogleUser?> get onCurrentUserChanged => _userChanges.stream;

  /// Interactive sign in flow. Returns null if the user cancels. On web it
  /// must be called straight from a click, or the browser blocks the popup.
  Future<GoogleUser?> signIn() async {
    await _ensureInitialized();
    if (kIsWeb) return _signInWeb();
    if (!_googleSignIn.supportsAuthenticate()) return null;
    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate(scopeHint: defaultScopes);
    } on GoogleSignInException catch (e) {
      // Closing the account picker is not an error.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final user = GoogleUser.fromIdentity(account);
    _setUser(user);
    await _saveUser(user);
    // Scopes are no longer granted at sign-in; ask while we still have the
    // user's tap, so backups work without a separate "Authorize" step.
    try {
      await _authorize(promptIfUnauthorized: true);
    } on GoogleSignInException catch (e) {
      debugPrint('Google scope authorization skipped: ${e.code}');
    }
    return user;
  }

  Future<GoogleUser?> _signInWeb() async {
    final ClientAuthorizationTokenData? tokens;
    try {
      tokens = await GoogleSignInPlatform.instance
          .clientAuthorizationTokensForScopes(
            const ClientAuthorizationTokensForScopesParameters(
              request: AuthorizationRequestDetails(
                scopes: _webSignInScopes,
                userId: null,
                email: null,
                promptIfUnauthorized: true,
              ),
            ),
          );
    } on GoogleSignInException catch (e) {
      // Closing the popup is not an error.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    if (tokens == null) return null;
    final client = GoogleSignInClientAuthorization(
      accessToken: tokens.accessToken,
    ).authClient(scopes: _webSignInScopes);
    try {
      final info = await oauth2.Oauth2Api(client).userinfo.get();
      final user = GoogleUser(
        id: info.id!,
        email: info.email!,
        displayName: info.name,
      );
      _setUser(user);
      await _saveUser(user);
      return user;
    } finally {
      client.close();
    }
  }

  /// Access tokens for [defaultScopes], for the current user. Returns null
  /// when [promptIfUnauthorized] is false and the user would have to approve.
  Future<GoogleSignInClientAuthorization?> _authorize({
    required bool promptIfUnauthorized,
  }) async {
    final user = _currentUser;
    if (user == null) return null;
    await _ensureInitialized();
    // On web the plugin caches tokens per userId, and passing one also forces
    // the account chooser; the page has a single user, so web leaves it out.
    // GoogleSignInAccount.authorizationClient makes this same call, but an
    // account object only comes from a fresh sign-in.
    final tokens = await GoogleSignInPlatform.instance
        .clientAuthorizationTokensForScopes(
          ClientAuthorizationTokensForScopesParameters(
            request: AuthorizationRequestDetails(
              scopes: defaultScopes,
              userId: kIsWeb ? null : user.id,
              email: kIsWeb ? null : user.email,
              promptIfUnauthorized: promptIfUnauthorized,
            ),
          ),
        );
    return tokens == null
        ? null
        : GoogleSignInClientAuthorization(accessToken: tokens.accessToken);
  }

  /// Checks whether required scopes are authorized without showing any UI or popups.
  Future<bool> canAccessScopes() async {
    try {
      return await _authorize(promptIfUnauthorized: false) != null;
    } catch (e) {
      debugPrint('canAccessScopes check error: $e');
      return false;
    }
  }

  /// Explicitly requests Drive and Gmail scopes via user-gesture popup.
  Future<bool> requestScopes() async {
    try {
      return await _authorize(promptIfUnauthorized: true) != null;
    } catch (e) {
      debugPrint('requestScopes error: $e');
      return false;
    }
  }

  /// Restores the remembered account without showing any UI (app startup
  /// and background sync).
  Future<GoogleUser?> signInSilently() async {
    try {
      final saved = _currentUser ?? await _loadSavedUser();
      _setUser(saved);
      return saved;
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
      await _saveUser(null);
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
      if (_currentUser == null && await signInSilently() == null) {
        debugPrint('getAuthenticatedClient: No user logged in');
        return null;
      }
      final authorization = await _authorize(promptIfUnauthorized: false);
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
