import 'dart:async';

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
        '„APIs & Dienste → Anmeldedaten“ einen OAuth-Client vom Typ „Android“ anlegen: '
        'Paketname $_androidApplicationId und SHA-1 des Debug-Keystores eintragen '
        '(Skript: flutter/scripts/print_android_debug_sha1.ps1). '
        'Danach App neu installieren/starten.',
      );
    }
    throw Exception(e.message ?? e.code);
  }

  Future<GoogleAuthPayload> signInBasic() async {
    try {
    final account = await _signIn.signIn();
    if (account == null) {
      throw Exception('Google Sign-In abgebrochen');
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    final serverAuthCode = account.serverAuthCode;
    if (idToken == null || serverAuthCode == null) {
      throw Exception('Google Sign-In Token fehlen (idToken/serverAuthCode)');
    }
    return GoogleAuthPayload(idToken: idToken, serverAuthCode: serverAuthCode);
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
      final account = _signIn.currentUser ?? await _signIn.signInSilently();
      if (account == null) {
        // Force interactive sign in to allow adding scopes
        await signInBasic();
      }
      final ok = await _signIn.requestScopes(scopes);
      if (!ok) {
        throw Exception('Google Berechtigungen wurden nicht erteilt');
      }
      // Play Services liefert den neuen serverAuthCode oft erst kurz nach requestScopes.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    // Refresh the auth code after scope changes
    final account = _signIn.currentUser ?? await _signIn.signInSilently();
    if (account == null) {
      throw Exception('Google Sign-In nicht verbunden');
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    final serverAuthCode = account.serverAuthCode;
    if (idToken == null || serverAuthCode == null) {
      throw Exception('Google Sign-In Token fehlen (idToken/serverAuthCode)');
    }
    return GoogleAuthPayload(idToken: idToken, serverAuthCode: serverAuthCode);
    } on PlatformException catch (e) {
      _rethrowGooglePlatform(e);
    }
  }

  Future<void> signOut() => _signIn.signOut();

  Future<void> disconnect() => _signIn.disconnect();
}

