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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popular esta Semana'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(
                  child: Text('No hay publicaciones destacadas esta semana todavía.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadPopular,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
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
        title: const Text('Mi Perfil Ciudadano'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildGuestView()
              : _buildUserProfile(),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Modo Invitado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Estás explorando la comunidad sin iniciar sesión. Crea tu cuenta para sumar puntos de reputación y confirmar reportes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Iniciar Sesión o Registrarme'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    final initials = _user!.username.isNotEmpty ? _user!.username.substring(0, 1).toUpperCase() : 'RD';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: Theme.of(context).colorScheme.secondary,
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)),
            ),
            child: Text(
              'Nivel: ${_user!.reputationLevel}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),

          // Metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('Reportes', '${_user!.totalPosts}'),
              _buildStat('Confirmaciones', '${_user!.totalConfirmations}'),
              _buildStat('Reputación', '${_user!.reputationScore} pts'),
            ],
          ),
          const SizedBox(height: 32),

          // Details List
          ListTile(
            leading: Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.secondary),
            title: Text('Provincia: ${_user!.province ?? "República Dominicana"}'),
            subtitle: _user!.municipality != null ? Text('Municipio: ${_user!.municipality}') : null,
          ),
          ListTile(
            leading: Icon(Icons.calendar_today_outlined, color: Theme.of(context).colorScheme.secondary),
            title: const Text('Miembro de la comunidad desde'),
            subtitle: Text('${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'),
          ),
          ListTile(
            leading: Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.secondary),
            title: const Text('Normas comunitarias y Privacidad'),
            trailing: const Icon(Icons.chevron_right),
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
          ListTile(
            leading: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
            title: const Text('Tema y Apariencia (Rosé Pine)'),
            subtitle: Text(_getThemeName(AppTheme.themeNotifier.value)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showThemeSelector,
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Rosé Pine Dawn (Claro)';
      case ThemeMode.dark:
        return 'Rosé Pine (Oscuro)';
      case ThemeMode.system:
        return 'Automático (Sistema)';
    }
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema de la Aplicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                AppTheme.themeNotifier.value == ThemeMode.dark
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Rosé Pine (Oscuro)'),
              subtitle: const Text('Paleta oscura de FinanzApp'),
              onTap: () {
                AppTheme.themeNotifier.value = ThemeMode.dark;
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: Icon(
                AppTheme.themeNotifier.value == ThemeMode.light
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Rosé Pine Dawn (Claro)'),
              subtitle: const Text('Paleta clara minimalista'),
              onTap: () {
                AppTheme.themeNotifier.value = ThemeMode.light;
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: Icon(
                AppTheme.themeNotifier.value == ThemeMode.system
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Automático'),
              subtitle: const Text('Sigue el sistema operativo'),
              onTap: () {
                AppTheme.themeNotifier.value = ThemeMode.system;
                Navigator.pop(context);
                setState(() {});
              },
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
