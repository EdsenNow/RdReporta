import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/rdreporta_logo.dart';
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

    final loggedIn = await _apiClient.restoreSession();

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
            const RdReportaLogo(size: 132),
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
              'Información e incidencias en República Dominicana',
              style: TextStyle(
                color: context.subtleColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
