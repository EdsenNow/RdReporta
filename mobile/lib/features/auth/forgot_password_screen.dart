import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  void _submitRecovery() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: _submitted
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 72, color: RosePineDark.success),
                      const SizedBox(height: 16),
                      Text(
                        '¡Enlace Enviado!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hemos enviado las instrucciones para restablecer tu contraseña a ${_emailController.text}. Revisa tu bandeja de entrada o spam.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: context.subtleColor),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Volver al Inicio de Sesión'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa el correo electrónico asociado a tu cuenta para recibir un enlace de recuperación.',
                        style: TextStyle(fontSize: 14, color: context.subtleColor),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Ingresa tu correo';
                          if (!val.contains('@')) return 'Ingresa un correo válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitRecovery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Enviar enlace de recuperación',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
