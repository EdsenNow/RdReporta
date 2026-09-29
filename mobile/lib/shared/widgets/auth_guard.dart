import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../features/auth/login_screen.dart';

Future<bool> requireSession(BuildContext context) async {
  if (await ApiClient().isLoggedIn()) return context.mounted;
  if (!context.mounted) return false;
  await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.person_outline, size: 42),
                  const SizedBox(height: 12),
                  const Text('Participa en tu comunidad',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                      'Inicia sesión para publicar, confirmar o denunciar una incidencia.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen(
                                    initialView: AuthView.emailLogin)));
                      },
                      child: const Text('Iniciar sesión')),
                  TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Seguir explorando')),
                ])),
          ));
  return false;
}
