import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/incident_card.dart';
import 'auth/login_screen.dart';

class PopularScreen extends StatefulWidget {
  const PopularScreen({super.key});

  @override
  State<PopularScreen> createState() => _PopularScreenState();
}

class _PopularScreenState extends State<PopularScreen> {
  final ApiClient _apiClient = ApiClient();
  List<PostModel> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPopular();
  }

  Future<void> _loadPopular() async {
    setState(() => _loading = true);
    final list = await _apiClient.getPopularPosts();
    setState(() {
      _posts = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Popular esta Semana',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.loveColor,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.loveColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: context.loveColor,
                size: 20,
              ),
              tooltip: isDark ? 'Cambiar a Rosé Pine Dawn (Claro)' : 'Cambiar a Rosé Pine (Oscuro)',
              onPressed: () {
                AppTheme.toggleTheme();
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.loveColor, strokeWidth: 2.5))
          : _posts.isEmpty
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0x1AFFFFFF) : context.borderColor,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_outlined, size: 48, color: context.loveColor),
                        const SizedBox(height: 12),
                        Text(
                          'Tendencias en curso',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Aún no hay publicaciones con alta interacción ciudadana esta semana.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: context.subtleColor),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: context.loveColor,
                  onRefresh: _loadPopular,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 90),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) => IncidentCard(post: _posts[index]),
                  ),
                ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final user = await _apiClient.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tendrás que volver a iniciar sesión para confirmar incidencias o publicar reportes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiClient.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Perfil Ciudadano',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.loveColor,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.loveColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: Icon(
                context.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: context.loveColor,
                size: 20,
              ),
              tooltip: context.isDarkMode ? 'Cambiar a Rosé Pine Dawn (Claro)' : 'Cambiar a Rosé Pine (Oscuro)',
              onPressed: () {
                AppTheme.toggleTheme();
                setState(() {});
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.loveColor, strokeWidth: 2.5))
          : _user == null
              ? _buildGuestView()
              : _buildUserProfile(),
    );
  }

  Widget _buildGuestView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      child: Column(
        children: [
          // 1. Selector de Apariencia y Tema (Rosé Pine / Dawn) - Siempre visible
          _buildThemeSelectorCard(),

          const SizedBox(height: 12),

          // 2. Tarjeta de Modo Invitado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDarkMode ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: context.overlayColor,
                  child: Icon(Icons.account_circle_outlined, size: 48, color: context.mutedColor),
                ),
                const SizedBox(height: 14),
                Text(
                  'Modo Invitado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estás explorando la comunidad sin iniciar sesión. Crea tu cuenta para sumar puntos de reputación y confirmar reportes en tu sector.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: context.subtleColor, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.loveColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Iniciar Sesión o Registrarme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Tarjeta de Privacidad y Normas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor, width: 1.2),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.shield_outlined, color: context.pineColor),
              title: Text('Compromiso de Privacidad', style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
              subtitle: Text('RDReporta no comparte coordenadas privadas personales.', style: TextStyle(fontSize: 12, color: context.subtleColor)),
              trailing: Icon(Icons.chevron_right, color: context.mutedColor),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Compromiso de Privacidad'),
                    content: const Text(
                      'En RDReporta no se revelan tus coordenadas privadas personales ni existen mensajes directos o comentarios públicos. Solo se comparte la información explícita de incidencias ciudadanas.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    final initials = _user!.username.isNotEmpty ? _user!.username.substring(0, 1).toUpperCase() : 'RD';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: context.pineColor,
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '@${_user!.username}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            _user!.email,
            style: TextStyle(fontSize: 13, color: context.subtleColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.loveColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.loveColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              'Nivel: ${_user!.reputationLevel}',
              style: TextStyle(color: context.loveColor, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('Reportes', '${_user!.totalPosts}'),
              _buildStat('Confirmaciones', '${_user!.totalConfirmations}'),
              _buildStat('Reputación', '${_user!.reputationScore} pts'),
            ],
          ),
          const SizedBox(height: 16),

          // Selector de Apariencia y Tema (Rosé Pine)
          _buildThemeSelectorCard(),

          const SizedBox(height: 12),

          // Details List
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor, width: 1.2),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.location_on_outlined, color: context.pineColor),
                  title: Text('Provincia: ${_user!.province ?? "República Dominicana"}', style: TextStyle(color: context.textPrimaryColor)),
                  subtitle: _user!.municipality != null ? Text('Municipio: ${_user!.municipality}', style: TextStyle(color: context.subtleColor)) : null,
                ),
                Divider(color: context.borderColor),
                ListTile(
                  leading: Icon(Icons.calendar_today_outlined, color: context.pineColor),
                  title: Text('Miembro desde', style: TextStyle(color: context.textPrimaryColor)),
                  subtitle: Text('${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}', style: TextStyle(color: context.subtleColor)),
                ),
                Divider(color: context.borderColor),
                ListTile(
                  leading: Icon(Icons.shield_outlined, color: context.pineColor),
                  title: Text('Normas comunitarias y Privacidad', style: TextStyle(color: context.textPrimaryColor)),
                  trailing: Icon(Icons.chevron_right, color: context.mutedColor),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Compromiso de Privacidad'),
                        content: const Text(
                          'En RDReporta no se revelan tus coordenadas privadas personales ni existen mensajes directos o comentarios públicos. Solo se comparte la información explícita de incidencias ciudadanas.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
                        ],
                      ),
                    );
                  },
                ),
                Divider(color: context.borderColor),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelectorCard() {
    final currentMode = AppTheme.themeNotifier.value;
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x26E0DEF4) : context.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.loveColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.palette_outlined, size: 20, color: context.loveColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apariencia y Tema',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Personaliza los colores de la aplicación',
                      style: TextStyle(fontSize: 12, color: context.subtleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Opciones de tema (Oscuro, Claro, Auto)
          Row(
            children: [
              Expanded(
                child: _buildThemeOptionPill(
                  title: 'Oscuro',
                  subtitle: 'Rosé Pine',
                  icon: Icons.dark_mode_rounded,
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () async {
                    await AppTheme.setTheme(ThemeMode.dark);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOptionPill(
                  title: 'Claro',
                  subtitle: 'Dawn',
                  icon: Icons.light_mode_rounded,
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () async {
                    await AppTheme.setTheme(ThemeMode.light);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOptionPill(
                  title: 'Auto',
                  subtitle: 'Sistema',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () async {
                    await AppTheme.setTheme(ThemeMode.system);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionPill({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? context.overlayColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? context.loveColor : context.borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? context.loveColor : context.mutedColor,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? context.loveColor : context.textPrimaryColor,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? context.loveColor.withValues(alpha: 0.85) : context.mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildStat(String label, String value) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: context.subtleColor)),
      ],
    );
  }
}
