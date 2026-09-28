import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Breve pausa para mostrar el logo y diseño patrio
    await Future.delayed(const Duration(milliseconds: 900));

    final loggedIn = await _apiClient.isLoggedIn();

    if (mounted) {
      if (loggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary, // Pine
                    theme.colorScheme.primary,   // Love
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.borderColor, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'RD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'RDReporta',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Información e Incidencias en República Dominicana',
              style: TextStyle(
                color: context.subtleColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
