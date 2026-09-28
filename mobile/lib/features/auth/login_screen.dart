import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atmospheric_background.dart';
import '../home/home_screen.dart';

enum AuthView { options, emailLogin, register, forgotPassword }

class LoginScreen extends StatefulWidget {
  final AuthView initialView;

  const LoginScreen({super.key, this.initialView = AuthView.options});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthView _currentView;

  // Form Keys
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  final ApiClient _apiClient = ApiClient();

  bool _obscurePassword = true;
  bool _obscureRegPassword = true;
  bool _obscureRegConfirm = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _recoverySubmitted = false;

  String _selectedProvince = 'Distrito Nacional';
  final List<String> _provinces = [
    'Distrito Nacional', 'Santo Domingo', 'Santiago', 'La Vega', 
    'San Cristóbal', 'Puerto Plata', 'La Altagracia', 'San Pedro de Macorís', 
    'Duarte', 'La Romana', 'Espaillat', 'San Juan', 'Peravia', 'Barahona'
  ];

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  // --- Acciones de Autenticación ---

  void _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
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
      _showSnackbar(res['message'] ?? 'Error al iniciar sesión', isError: true);
    }
  }

  void _submitRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    if (_regPasswordController.text != _regConfirmPasswordController.text) {
      _showSnackbar('Las contraseñas no coinciden', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final res = await _apiClient.register(
      username: _regUsernameController.text.trim(),
      email: _regEmailController.text.trim(),
      password: _regPasswordController.text,
      province: _selectedProvince,
      municipality: _selectedProvince,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _showSnackbar('¡Cuenta creada exitosamente! Bienvenido.', isError: false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showSnackbar(res['message'] ?? 'Error al registrar usuario', isError: true);
    }
  }

  void _submitRecovery() {
    if (!_forgotFormKey.currentState!.validate()) return;
    setState(() => _recoverySubmitted = true);
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isLoading = false);

    _showSnackbar('Conectando con Google Sign-In...', isError: false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _handleAppleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isLoading = false);

    _showSnackbar('Conectando con Sign in with Apple...', isError: false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEB6F92) : RosePineDark.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AtmosphericBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 34.0),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0x26E0DEF4) : context.borderColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildCurrentView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case AuthView.options:
        return _buildOptionsView();
      case AuthView.emailLogin:
        return _buildEmailLoginView();
      case AuthView.register:
        return _buildRegisterView();
      case AuthView.forgotPassword:
        return _buildForgotPasswordView();
    }
  }

  // ==========================================
  // 1. VISTA DE OPCIONES (IDÉNTICA A FINANZAPP)
  // ==========================================
  Widget _buildOptionsView() {
    final isDark = context.isDarkMode;

    return Column(
      key: const ValueKey('options_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo de la App
        Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: context.loveColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: context.loveColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
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

        // Título "Bienvenido"
        Text(
          'Bienvenido',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),

        // Subtítulo "Accede a tu cuenta"
        Text(
          'Accede a tu cuenta',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: context.subtleColor,
          ),
        ),
        const SizedBox(height: 30),

        // Botón: Continuar con Google
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleGoogleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFE0DEF4) : const Color(0xFFF4F1EA),
              foregroundColor: isDark ? const Color(0xFF575279) : const Color(0xFF1F1D2E),
              elevation: 0,
              side: BorderSide(color: isDark ? Colors.transparent : context.borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoogleIcon(),
                const SizedBox(width: 10),
                Text(
                  'Continuar con Google',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF575279) : const Color(0xFF1F1D2E),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Botón: Continuar con Apple
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _handleAppleLogin,
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF151320) : const Color(0xFF1F1D2E),
              side: BorderSide(color: isDark ? const Color(0x28FFFFFF) : context.borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.apple, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Continuar con Apple',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Separador "o"
        Row(
          children: [
            Expanded(child: Divider(color: context.borderColor, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Text(
                'o',
                style: TextStyle(fontSize: 13, color: context.mutedColor),
              ),
            ),
            Expanded(child: Divider(color: context.borderColor, thickness: 1)),
          ],
        ),
        const SizedBox(height: 18),

        // Botón: Continuar con correo
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _currentView = AuthView.emailLogin),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.loveColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.mail_outline, size: 20),
            label: const Text(
              'Continuar con correo',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Continuar como invitado
        Center(
          child: TextButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            icon: Icon(Icons.person_outline, size: 18, color: context.mutedColor),
            label: Text(
              'Continuar como invitado',
              style: TextStyle(color: context.subtleColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Footer: ¿No tienes cuenta? Regístrate
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No tienes cuenta? ',
              style: TextStyle(color: context.mutedColor, fontSize: 13),
            ),
            GestureDetector(
              onTap: () => setState(() => _currentView = AuthView.register),
              child: Text(
                'Regístrate',
                style: TextStyle(
                  color: context.loveColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Footer Legal
        Text(
          'Política de Privacidad · Condiciones del Servicio',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: context.mutedColor),
        ),
      ],
    );
  }

  // ==========================================
  // 2. VISTA DE INICIAR SESIÓN CON CORREO
  // ==========================================
  Widget _buildEmailLoginView() {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('email_login_view'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Iniciar Sesión',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa a tu cuenta',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.subtleColor),
          ),
          const SizedBox(height: 26),

          // Correo Electrónico
          _buildInputLabel('Correo Electrónico'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
            decoration: _buildInputDecoration(
              hint: 'ejemplo@correo.com',
              icon: Icons.email_outlined,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Ingresa tu correo';
              if (!val.contains('@')) return 'Ingresa un correo válido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Contraseña
          _buildInputLabel('Contraseña'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
            decoration: _buildInputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: context.mutedColor,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Ingresa tu contraseña';
              if (val.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),

          // ¿Olvidaste tu contraseña?
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _currentView = AuthView.forgotPassword),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(color: context.loveColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Recordar sesión
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: context.loveColor,
                  checkColor: Colors.white,
                  side: BorderSide(color: context.borderColor),
                  onChanged: (val) => setState(() => _rememberMe = val ?? true),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recordar sesión',
                style: TextStyle(color: context.subtleColor, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botón Iniciar Sesión
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.loveColor,
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
          const SizedBox(height: 12),

          // Botón Volver atrás
          TextButton.icon(
            onPressed: () => setState(() => _currentView = AuthView.options),
            icon: Icon(Icons.arrow_back, size: 18, color: context.mutedColor),
            label: Text(
              'Volver atrás',
              style: TextStyle(color: context.subtleColor, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No tienes cuenta? ',
                style: TextStyle(color: context.mutedColor, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentView = AuthView.register),
                child: Text(
                  'Regístrate',
                  style: TextStyle(
                    color: context.loveColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. VISTA DE REGISTRO
  // ==========================================
  Widget _buildRegisterView() {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register_view'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Crear Cuenta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Regístrate para comenzar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.subtleColor),
          ),
          const SizedBox(height: 22),

          _buildInputLabel('Nombre de Usuario'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _regUsernameController,
            style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
            decoration: _buildInputDecoration(hint: 'ej. juan_perez', icon: Icons.person_outline),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Ingresa un usuario';
              if (val.trim().length < 3) return 'Mínimo 3 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 14),

          _buildInputLabel('Correo Electrónico'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
            decoration: _buildInputDecoration(hint: 'ejemplo@correo.com', icon: Icons.email_outlined),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Ingresa tu correo';
              if (!val.contains('@')) return 'Correo no válido';
              return null;
            },
          ),
          const SizedBox(height: 14),

          _buildInputLabel('Provincia'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedProvince,
            dropdownColor: context.surfaceColor,
            style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
            decoration: _buildInputDecoration(hint: '', icon: Icons.location_on_outlined),
            items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: context.textPrimaryColor)))).toList(),
            onChanged: (val) => setState(() => _selectedProvince = val!),
          ),
          const SizedBox(height: 14),

          _buildInputLabel('Contraseña'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _regPasswordController,
            obscureText: _obscureRegPassword,
            style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
            decoration: _buildInputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscureRegPassword ? Icons.visibility_off : Icons.visibility,
                  color: context.mutedColor,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Ingresa tu contraseña';
              if (val.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 14),

          _buildInputLabel('Confirmar Contraseña'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _regConfirmPasswordController,
            obscureText: _obscureRegConfirm,
            style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
            decoration: _buildInputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscureRegConfirm ? Icons.visibility_off : Icons.visibility,
                  color: context.mutedColor,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureRegConfirm = !_obscureRegConfirm),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Confirma tu contraseña';
              return null;
            },
          ),
          const SizedBox(height: 22),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.loveColor,
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
                      'Crear Cuenta',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: () => setState(() => _currentView = AuthView.options),
            icon: Icon(Icons.arrow_back, size: 18, color: context.mutedColor),
            label: Text(
              'Volver atrás',
              style: TextStyle(color: context.subtleColor, fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿Ya tienes cuenta? ',
                style: TextStyle(color: context.mutedColor, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentView = AuthView.emailLogin),
                child: Text(
                  'Inicia Sesión',
                  style: TextStyle(
                    color: context.loveColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. VISTA DE RECUPERAR CONTRASEÑA
  // ==========================================
  Widget _buildForgotPasswordView() {
    return Form(
      key: _forgotFormKey,
      child: Column(
        key: const ValueKey('forgot_view'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recuperar Contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa tu correo para restablecerla',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.subtleColor),
          ),
          const SizedBox(height: 26),

          if (_recoverySubmitted) ...[
            Center(
              child: Column(
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 64, color: RosePineDark.success),
                  const SizedBox(height: 14),
                  Text(
                    '¡Enlace Enviado!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hemos enviado el enlace a ${_forgotEmailController.text}. Revisa tu bandeja de entrada.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: context.subtleColor),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() {
                        _recoverySubmitted = false;
                        _currentView = AuthView.emailLogin;
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.loveColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Volver a Iniciar Sesión'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildInputLabel('Correo Electrónico'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _forgotEmailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
              decoration: _buildInputDecoration(hint: 'ejemplo@correo.com', icon: Icons.email_outlined),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Ingresa tu correo';
                if (!val.contains('@')) return 'Correo no válido';
                return null;
              },
            ),
            const SizedBox(height: 22),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitRecovery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.loveColor,
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
            const SizedBox(height: 14),

            TextButton.icon(
              onPressed: () => setState(() => _currentView = AuthView.emailLogin),
              icon: Icon(Icons.arrow_back, size: 18, color: context.mutedColor),
              label: Text(
                'Volver a Iniciar Sesión',
                style: TextStyle(color: context.subtleColor, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.subtleColor,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.mutedColor, fontSize: 13),
      prefixIcon: Icon(icon, color: context.mutedColor, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: context.overlayColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.loveColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.loveColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.loveColor, width: 1.5),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
