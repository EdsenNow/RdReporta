import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'networking/api_client.dart';

class FirebaseService {
  static bool _ready = false;
  static bool _disconnecting = false;
  static Future<void>? _syncing;
  static final messages = StreamController<RemoteMessage>.broadcast();
  static final pendingOpen = ValueNotifier<RemoteMessage?>(null);

  static Future<void> initialize() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
      _ready = true;
      // Home shows a banner in the foreground on both platforms.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      FirebaseMessaging.onMessage.listen((message) {
        unawaited(ApiClient().refreshUnreadNotifications());
        messages.add(message);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        pendingOpen.value = message;
      });
      FirebaseMessaging.instance.onTokenRefresh.listen((_) {
        unawaited(syncToken());
      }, onError: (Object _) {
        debugPrint(
            'No se pudo renovar el registro push. Se reintentará al volver a la app.');
      });
      ApiClient().beforeLogout = disconnect;
      ApiClient().sessionChanges.addListener(_sessionChanged);
      pendingOpen.value = await FirebaseMessaging.instance.getInitialMessage();
    } catch (_) {
      debugPrint(
          'Firebase no está disponible; la bandeja de notificaciones sigue activa.');
    }
  }

  static void _sessionChanged() {
    unawaited(_handleSession());
  }

  static Future<void> _handleSession() async {
    if (await ApiClient().isLoggedIn()) {
      await syncToken();
    } else {
      pendingOpen.value = null;
      try {
        await _syncing;
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {/* Retry registration on the next session. */}
    }
  }

  static Future<void> syncToken() {
    if (!_ready || _disconnecting) return Future.value();
    return _syncing ??= _register().whenComplete(() => _syncing = null);
  }

  static Future<void> _register() async {
    try {
      final api = ApiClient();
      if (!await api.isLoggedIn()) return;
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        await api.unregisterDeviceToken();
        return;
      }
      if (Platform.isIOS &&
          await FirebaseMessaging.instance.getAPNSToken() == null) {
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || _disconnecting || !await api.isLoggedIn()) return;
      await api.registerDeviceToken(token, Platform.operatingSystem);
    } catch (_) {
      debugPrint(
          'No se pudo registrar push. Se reintentará al volver a la app.');
    }
  }

  static Future<void> disconnect() async {
    _disconnecting = true;
    pendingOpen.value = null;
    try {
      await _syncing;
      try {
        await ApiClient().unregisterDeviceToken();
      } catch (_) {}
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
    } finally {
      _disconnecting = false;
    }
  }
}
