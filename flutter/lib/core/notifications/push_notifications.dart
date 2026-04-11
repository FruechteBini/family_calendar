import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

final pushNotificationsProvider = Provider<PushNotificationsService>((ref) {
  return PushNotificationsService(ref);
});

class PushNotificationsService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _available = false;

  PushNotificationsService(this._ref);

  bool get isAvailable => _available;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // If platform configs are not present yet, Firebase init can throw.
      await Firebase.initializeApp();
    } catch (_) {
      _available = false;
      return;
    }

    _available = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    await _requestPermission();
    await _syncTokenWithBackend();

    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      await _upsertToken(t);
    });

    FirebaseMessaging.onMessage.listen((message) async {
      final n = message.notification;
      if (n == null) return;
      await _local.show(
        message.hashCode,
        n.title,
        n.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'familienkalender_default',
            'Benachrichtigungen',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        payload: message.data['route'],
      );
    });
  }

  Future<void> _requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // ignored
    }
  }

  Future<void> _syncTokenWithBackend() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _upsertToken(token);
    } catch (_) {
      // ignored
    }
  }

  Future<void> _upsertToken(String token) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/api/notifications/device-token', data: {
        'token': token,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      });
    } catch (_) {
      // ignored
    }
  }
}

