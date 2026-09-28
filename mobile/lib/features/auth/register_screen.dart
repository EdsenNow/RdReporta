import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  String _selectedProvince = 'Distrito Nacional';
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _provinces = [
    'Distrito Nacional', 'Santo Domingo', 'Santiago', 'La Vega', 
    'San Cristóbal', 'Puerto Plata', 'La Altagracia', 'San Pedro de Macorís', 
    'Duarte', 'La Romana', 'Espaillat', 'San Juan', 'Peravia', 'Barahona'
  ];

  void _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await _apiClient.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      province: _selectedProvince,
      municipality: _selectedProvince,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada exitosamente! Bienvenido a RDReporta.'),
          backgroundColor: AppTheme.confirmationGreen,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Error al registrar usuario'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Únete a RDReporta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sé parte de la red de ciudadanos que informan y colaboran con su comunidad en República Dominicana.',
                  style: TextStyle(fontSize: 13, color: context.subtleColor),
                ),
                const SizedBox(height: 24),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    hintText: 'ej. juan_perez',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingresa un nombre de usuario';
                    if (val.trim().length < 3) return 'Mínimo 3 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
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

                // Province Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvince,
                  dropdownColor: context.surfaceColor,
                  decoration: const InputDecoration(
                    labelText: 'Provincia de residencia',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setState(() => _selectedProvince = val!),
                ),
                const SizedBox(height: 16),

                // Password
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
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Confirma tu contraseña';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegister,
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
                            'Registrarme',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya tienes cuenta? ', style: TextStyle(color: context.subtleColor)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
