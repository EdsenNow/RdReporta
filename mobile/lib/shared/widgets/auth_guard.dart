import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../features/auth/login_screen.dart';

Future<bool> requireSession(BuildContext context) async {
  if (await ApiClient().isLoggedIn()) return context.mounted;
  if (!context.mounted) return false;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
  return false;
}
