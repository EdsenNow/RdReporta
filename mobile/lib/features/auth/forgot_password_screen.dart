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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: _submitted
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 72, color: AppTheme.confirmationGreen),
                      const SizedBox(height: 16),
                      const Text(
                        '¡Enlace Enviado!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hemos enviado las instrucciones para restablecer tu contraseña a ${_emailController.text}. Revisa tu bandeja de entrada o spam.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
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
                      const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresa el correo electrónico asociado a tu cuenta para recibir un enlace de recuperación.',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
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
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                          child: const Text('Enviar enlace de recuperación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
