import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  bool _obscurePassword = true;
  bool _isLoading = false;

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final res = await _apiClient.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Error al iniciar sesión'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    // Simulating OAuth Google flow
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conectando con Google Sign-In...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _handleAppleLogin() async {
    setState(() => _isLoading = true);
    // Simulating Apple ID flow
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conectando con Sign in with Apple...'),
        backgroundColor: Colors.black,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Logo (Minimalist Rosé Pine Container)
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary, // Pine
                            theme.colorScheme.primary,   // Love
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.borderColor,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'RD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'RDReporta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Información ciudadana e incidencias en tiempo real',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.subtleColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Ingresa tu correo';
                      if (!val.contains('@')) return 'Ingresa un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Ingresa tu contraseña';
                      if (val.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider "o continúa con"
                  Row(
                    children: [
                      Expanded(child: Divider(color: context.borderColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'o continúa con',
                          style: TextStyle(fontSize: 12, color: context.mutedColor),
                        ),
                      ),
                      Expanded(child: Divider(color: context.borderColor)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Google Button (Minimalist Rosé Pine card)
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: context.surfaceColor,
                    ),
                    icon: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4285F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    label: Text(
                      'Continuar con Google',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Apple Button (Minimalist Rosé Pine surface)
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleAppleLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: isDark ? RosePineDark.overlay : const Color(0xFF18181B),
                    ),
                    icon: const Icon(Icons.apple, size: 22, color: Colors.white),
                    label: const Text(
                      'Continuar con Apple',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(color: context.subtleColor, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Regístrate aquí',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Guest explore link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    child: Text(
                      'Explorar como invitado →',
                      style: TextStyle(color: context.subtleColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
