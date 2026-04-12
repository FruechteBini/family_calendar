import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Must match `applicationId` in `android/app/build.gradle.kts`.
const _androidApplicationId = 'com.example.familienkalender';

class GoogleAuthPayload {
  final String idToken;
  final String serverAuthCode;

  const GoogleAuthPayload({required this.idToken, required this.serverAuthCode});
}

class GoogleAuthService {
  static const _serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final GoogleSignIn _signIn = GoogleSignIn(
    serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    scopes: const ['email', 'profile'],
    forceCodeForRefreshToken: true,
  );

  /// Google Play Services `ApiException: 10` = DEVELOPER_ERROR (SHA-1 / Android client).
  Never _rethrowGooglePlatform(PlatformException e) {
    final msg = e.message ?? '';
    if (e.code == 'sign_in_failed' &&
        (msg.contains('ApiException: 10') || msg.contains(': 10:'))) {
      throw Exception(
        'Google Sign-In: Entwickler-Konfiguration (Fehler 10). '
        'In der Google Cloud (gleiches Projekt wie die Web-Client-ID!) unter '
        '„APIs & Dienste → Anmeldedaten" einen OAuth-Client vom Typ „Android" anlegen: '
        'Paketname $_androidApplicationId und SHA-1 des Debug-Keystores eintragen '
        '(Skript: flutter/scripts/print_android_debug_sha1.ps1). '
        'Danach App neu installieren/starten.',
      );
    }
    throw Exception(e.message ?? e.code);
  }

  /// Extract [GoogleAuthPayload] from an account, retrying with disconnect+signIn if
  /// serverAuthCode is null (common after repeated sign-ins on the same device).
  Future<GoogleAuthPayload> _extractPayload(GoogleSignInAccount account) async {
    var auth = await account.authentication;
    var idToken = auth.idToken;
    var serverAuthCode = account.serverAuthCode;

    dev.log(
      'GoogleAuth: idToken=${idToken != null ? "ok(${idToken.length})" : "NULL"}, '
      'serverAuthCode=${serverAuthCode != null ? "ok(${serverAuthCode.length})" : "NULL"}, '
      'serverClientId=${_serverClientId.isEmpty ? "EMPTY" : "set(${_serverClientId.length})"}',
      name: 'GoogleAuthService',
    );

    if (_serverClientId.isEmpty) {
      throw Exception(
        'GOOGLE_SERVER_CLIENT_ID ist nicht gesetzt. '
        'App mit --dart-define-from-file=dart_defines.json starten '
        'oder GOOGLE_SERVER_CLIENT_ID in der Run-Config setzen.',
      );
    }

    if (idToken != null && serverAuthCode != null) {
      return GoogleAuthPayload(idToken: idToken, serverAuthCode: serverAuthCode);
    }

    // serverAuthCode is often null on repeated sign-ins. Force a fresh one.
    dev.log('GoogleAuth: serverAuthCode null — disconnect + re-signIn', name: 'GoogleAuthService');
    await _signIn.disconnect();
    final fresh = await _signIn.signIn();
    if (fresh == null) {
      throw Exception('Google Sign-In abgebrochen (retry)');
    }
    auth = await fresh.authentication;
    idToken = auth.idToken;
    serverAuthCode = fresh.serverAuthCode;

    dev.log(
      'GoogleAuth retry: idToken=${idToken != null ? "ok" : "NULL"}, '
      'serverAuthCode=${serverAuthCode != null ? "ok" : "NULL"}',
      name: 'GoogleAuthService',
    );

    if (idToken == null || serverAuthCode == null) {
      throw Exception(
        'Google Sign-In: Token fehlen nach Retry '
        '(idToken=${idToken != null}, serverAuthCode=${serverAuthCode != null}). '
        'Prüfe GOOGLE_SERVER_CLIENT_ID (Web-Client-ID) in dart_defines.json.',
      );
    }
    return GoogleAuthPayload(idToken: idToken, serverAuthCode: serverAuthCode);
  }

  Future<GoogleAuthPayload> signInBasic() async {
    try {
      final account = await _signIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In abgebrochen');
      }
      return await _extractPayload(account);
    } on PlatformException catch (e) {
      _rethrowGooglePlatform(e);
    }
  }

  Future<GoogleAuthPayload> requestSyncScopes({
    required bool calendar,
    required bool tasks,
  }) async {
    try {
      final scopes = <String>[];
      if (calendar) {
        scopes.add('https://www.googleapis.com/auth/calendar');
      }
      if (tasks) {
        scopes.add('https://www.googleapis.com/auth/tasks');
      }
      if (scopes.isNotEmpty) {
        var account = _signIn.currentUser ?? await _signIn.signInSilently();
        if (account == null) {
          await signInBasic();
          account = _signIn.currentUser;
        }
        final ok = await _signIn.requestScopes(scopes);
        if (!ok) {
          throw Exception('Google Berechtigungen wurden nicht erteilt');
        }
      }

      // After scope change we need a fresh serverAuthCode — disconnect forces a new one.
      await _signIn.disconnect();
      final fresh = await _signIn.signIn();
      if (fresh == null) {
        throw Exception('Google Sign-In nach Scope-Änderung abgebrochen');
      }
      return await _extractPayload(fresh);
    } on PlatformException catch (e) {
      _rethrowGooglePlatform(e);
    }
  }

  Future<void> signOut() => _signIn.signOut();

  Future<void> disconnect() => _signIn.disconnect();
}
