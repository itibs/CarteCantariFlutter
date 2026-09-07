import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:ccc_flutter/auth_config.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_state.dart';

/// Holds the app-level signed-in state.
///
/// The signed-in state is persisted in SharedPreferences so the app is
/// immediately "logged in" on a cold start even without internet. The Google
/// SDK session is only consulted lazily, to mint short-lived ID tokens right
/// before sync API calls.
class AuthCubit extends Cubit<AuthState> {
  GoogleSignInAccount? _account;
  Future<void>? _initFuture;
  final _signInEventsController =
      StreamController<GoogleSignInAccount>.broadcast();

  AuthCubit() : super(const AuthState.signedOut());

  /// Emitted whenever the Google SDK reports a sign-in. Used by the web
  /// sign-in dialog, where the flow is driven by Google's rendered button.
  Stream<GoogleSignInAccount> get signInEvents =>
      _signInEventsController.stream;

  /// Restores the persisted signed-in state (offline-safe) and warms up the
  /// Google SDK session in the background.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(PREFS_AUTH_SIGNED_IN) ?? false) {
      emit(AuthState(
        signedIn: true,
        email: prefs.getString(PREFS_AUTH_EMAIL),
        displayName: prefs.getString(PREFS_AUTH_DISPLAY_NAME),
        photoUrl: prefs.getString(PREFS_AUTH_PHOTO_URL),
      ));
    }
    try {
      await ensureInitialized();
      // Fire and forget: restores the SDK session when online so ID tokens
      // are available for sync; failing (e.g. offline) is fine.
      GoogleSignIn.instance
          .attemptLightweightAuthentication()
          ?.catchError((_) => null);
    } catch (_) {}
  }

  /// Initializes the Google Sign-In SDK (once). Public so the web login flow
  /// can await it before rendering Google's sign-in button.
  Future<void> ensureInitialized() {
    return _initFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? GOOGLE_WEB_CLIENT_ID : null,
        serverClientId: kIsWeb ? null : GOOGLE_WEB_CLIENT_ID,
      );
      GoogleSignIn.instance.authenticationEvents
          .listen(_onAuthenticationEvent, onError: (_) {});
    } catch (e) {
      // Allow a later retry instead of caching the failure forever.
      _initFuture = null;
      rethrow;
    }
  }

  void _onAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        _account = event.user;
        _signInEventsController.add(event.user);
      case GoogleSignInAuthenticationEventSignOut():
        _account = null;
    }
  }

  /// Starts the interactive sign-in flow (Android/iOS). Returns null if the
  /// user canceled. On web the flow is driven by [signInEvents] instead.
  Future<GoogleSignInAccount?> signInInteractive() async {
    await ensureInitialized();
    try {
      _account =
          await GoogleSignIn.instance.authenticate(scopeHint: const ['email']);
      return _account;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  /// Marks the account as signed in at the app level. Called only after the
  /// post-login sync flow succeeded.
  Future<void> completeSignIn(GoogleSignInAccount account) async {
    _account = account;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREFS_AUTH_SIGNED_IN, true);
    await prefs.setString(PREFS_AUTH_EMAIL, account.email);
    if (account.displayName != null) {
      await prefs.setString(PREFS_AUTH_DISPLAY_NAME, account.displayName!);
    } else {
      await prefs.remove(PREFS_AUTH_DISPLAY_NAME);
    }
    if (account.photoUrl != null) {
      await prefs.setString(PREFS_AUTH_PHOTO_URL, account.photoUrl!);
    } else {
      await prefs.remove(PREFS_AUTH_PHOTO_URL);
    }
    emit(AuthState(
      signedIn: true,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    ));
  }

  Future<void> signOut() async {
    try {
      await ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    _account = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREFS_AUTH_SIGNED_IN, false);
    await prefs.remove(PREFS_AUTH_EMAIL);
    await prefs.remove(PREFS_AUTH_DISPLAY_NAME);
    await prefs.remove(PREFS_AUTH_PHOTO_URL);
    emit(const AuthState.signedOut());
  }

  /// Returns a currently valid Google ID token, refreshing it through the SDK
  /// session if needed. Returns null when unavailable (e.g. offline), in which
  /// case sync is simply skipped.
  Future<String?> getIdToken() async {
    try {
      await ensureInitialized();
    } catch (_) {
      return null;
    }
    var token = _account?.authentication.idToken;
    if (token != null && !_isTokenExpired(token)) {
      return token;
    }
    try {
      final attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
      final account = attempt == null ? null : await attempt;
      if (account != null) {
        _account = account;
      }
    } catch (_) {}
    token = _account?.authentication.idToken;
    if (token != null && !_isTokenExpired(token)) {
      return token;
    }
    return null;
  }

  static bool _isTokenExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      final payload = json.decode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map<String, dynamic>;
      final exp = (payload['exp'] as num).toInt();
      // 60s safety margin so the token doesn't expire mid-request.
      return DateTime.now().millisecondsSinceEpoch >= (exp - 60) * 1000;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> close() {
    _signInEventsController.close();
    return super.close();
  }
}
