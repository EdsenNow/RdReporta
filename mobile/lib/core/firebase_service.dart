import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'networking/api_client.dart';

class FirebaseService {
  static bool _ready = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      _ready = true;
    } catch (_) {
      // Native Firebase files are added later with `flutterfire configure`.
      _ready = false;
    }
  }

  static Future<void> syncToken() async {
    if (!_ready || !await ApiClient().isLoggedIn()) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await ApiClient().registerDeviceToken(token, Platform.operatingSystem);
  }
}
