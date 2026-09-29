import 'package:flutter/material.dart';
import '../core/networking/api_client.dart';
import '../core/theme/app_theme.dart';
import '../shared/models/models.dart';
import '../shared/widgets/incident_card.dart';
import 'auth/login_screen.dart';
import '../shared/widgets/request_state.dart';
import 'profile/edit_profile_screen.dart';
import 'profile/my_posts_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/api_constants.dart';

PreferredSizeWidget _sectionHeader(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required List<Widget> actions,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(82),
    child: SafeArea(
      bottom: false,
      child: Container(
        height: 58,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.loveColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: context.loveColor, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.subtleColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    ),
  );
}

class PopularScreen extends StatefulWidget {
  const PopularScreen({super.key});

  @override
  State<PopularScreen> createState() => _PopularScreenState();
}

class _PopularScreenState extends State<PopularScreen> {
  final ApiClient _apiClient = ApiClient();
  List<PostModel> _posts = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadPopular();
    _apiClient.changes.addListener(_loadPopular);
  }

  @override
  void dispose() {
    _apiClient.changes.removeListener(_loadPopular);
    super.dispose();
  }

  Future<void> _loadPopular() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _apiClient.getPopularPosts();
      if (!mounted) return;
      setState(() {
        _posts = list;
        _page = 1;
        _hasMore = list.length == 20;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final next = await _apiClient.getPopularPosts(page: _page + 1);
      if (mounted) {
        setState(() {
          _page++;
          _hasMore = next.length == 20;
          final ids = _posts.map((p) => p.id).toSet();
          _posts.addAll(next.where((p) => !ids.contains(p.id)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: _sectionHeader(
        context,
        icon: Icons.local_fire_department_rounded,
        title: 'Popular esta semana',
        subtitle: 'Lo más relevante de la comunidad',
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: context.loveColor,
              size: 20,
            ),
            tooltip: isDark
                ? 'Cambiar a Rosé Pine Dawn (claro)'
                : 'Cambiar a Rosé Pine (oscuro)',
            onPressed: AppTheme.toggleTheme,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: context.loveColor, strokeWidth: 2.5))
          : _error != null
              ? RequestState(message: _error!, onRetry: _loadPopular)
              : _posts.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0x1AFFFFFF)
                                : context.borderColor,
                            width: isDark ? 1.2 : 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department_outlined,
                                size: 48, color: context.loveColor),
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
                              style: TextStyle(
                                  fontSize: 13, color: context.subtleColor),
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _posts.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) => index == _posts.length
                            ? TextButton(
                                onPressed: _loadingMore ? null : _loadMore,
                                child: Text(
                                    _loadingMore ? 'Cargando…' : 'Ver más'))
                            : IncidentCard(
                                key: ValueKey(_posts[index].id),
                                post: _posts[index]),
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
  String? _error;
  bool _avatarBusy = false;

  String _avatarUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    return '${ApiConstants.hostUrl}/${value.replaceFirst(RegExp(r'^/'), '')}';
  }

  Future<void> _changeAvatar() async {
    if (_avatarBusy || _user == null) return;
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null || !mounted) return;
    setState(() => _avatarBusy = true);
    try {
      final url = await _apiClient.uploadImage(image.path);
      if (url == null) throw Exception('No se pudo subir la imagen.');
      await _apiClient.updateProfile(avatarUrl: url);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Widget _buildEditableAvatar(String initials) {
    final avatar = _user?.avatarUrl;

    return Semantics(
      button: true,
      label: 'Cambiar foto de perfil',
      child: InkWell(
        onTap: _avatarBusy ? null : _changeAvatar,
        borderRadius: BorderRadius.circular(54),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.isDarkMode
                    ? context.overlayColor
                    : const Color(0xFFFFFAF3),
                border: Border.all(color: context.borderColor, width: 2),
              ),
              child: _avatarBusy
                  ? CircularProgressIndicator(
                      color: context.loveColor,
                      strokeWidth: 2.5,
                    )
                  : avatar != null && avatar.isNotEmpty
                      ? Image.network(
                          _avatarUrl(avatar),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            initials,
                            style: TextStyle(
                              color: context.loveColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Text(
                          initials,
                          style: TextStyle(
                            color: context.loveColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            ),
            Positioned(
              right: -2,
              bottom: 1,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.loveColor,
                  border: Border.all(color: context.surfaceColor, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _apiClient.changes.addListener(_loadProfile);
  }

  @override
  void dispose() {
    _apiClient.changes.removeListener(_loadProfile);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final loggedIn = await _apiClient.isLoggedIn();
    if (!loggedIn) {
      if (mounted) {
        setState(() {
          _user = null;
          _loading = false;
        });
      }
      return;
    }
    final user = await _apiClient.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        if (user == null) {
          _error =
              'No se pudo cargar tu perfil. Vuelve a intentar o inicia sesión de nuevo.';
        }
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
            'Tendrás que volver a iniciar sesión para confirmar incidencias o publicar reportes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
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
      appBar: _sectionHeader(
        context,
        icon: Icons.person_rounded,
        title: 'Mi perfil ciudadano',
        subtitle: _user == null ? 'Cuenta y preferencias' : '@${_user!.username}',
        actions: [
          IconButton(
            icon: Icon(
              context.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: context.loveColor,
              size: 20,
            ),
            tooltip: context.isDarkMode
                ? 'Cambiar a Rosé Pine Dawn (claro)'
                : 'Cambiar a Rosé Pine (oscuro)',
            onPressed: AppTheme.toggleTheme,
          ),
          if (_user != null)
            IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar perfil',
                onPressed: () async {
                  final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: _user!)));
                  if (saved == true && mounted) _loadProfile();
                }),
          if (_user != null)
            IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Mis reportes',
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MyPostsScreen()));
                }),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: context.loveColor, strokeWidth: 2.5))
          : _error != null
              ? RequestState(message: _error!, onRetry: _loadProfile)
              : RefreshIndicator(
                  color: context.loveColor,
                  onRefresh: _loadProfile,
                  child: _user == null
                      ? _buildGuestView()
                      : _buildUserProfile(),
                ),
    );
  }

  Widget _buildGuestView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      child: Column(
        children: [
          // 1. Selector de Apariencia y tema (Rosé Pine / Dawn) - Siempre visible
          _buildThemeSelectorCard(),

          const SizedBox(height: 12),

          // 2. Tarjeta de Modo invitado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor, width: 2),
),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: context.isDarkMode
                      ? context.overlayColor
                      : const Color(0xFFFFFAF3),
                  child: Icon(Icons.account_circle_outlined,
                      size: 48, color: context.mutedColor),
                ),
                const SizedBox(height: 14),
                Text(
                  'Modo invitado',
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
                  style: TextStyle(
                      fontSize: 13, color: context.subtleColor, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.loveColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Iniciar sesión o registrarme',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _buildPrivacyCard(),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showPrivacyDetails,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.pineColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.verified_user_outlined,
                        color: context.pineColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tu privacidad, primero',
                            style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text('Tú decides qué información compartir.',
                            style: TextStyle(
                                color: context.subtleColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: context.mutedColor),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _privacyBadge(Icons.location_off_outlined, 'Sin rastreo'),
                  _privacyBadge(Icons.lock_outline_rounded, 'Datos protegidos'),
                  _privacyBadge(Icons.forum_outlined, 'Sin mensajes privados'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: context.overlayColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.pineColor),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: context.subtleColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showPrivacyDetails() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.verified_user_outlined,
            color: context.pineColor, size: 32),
        title: const Text('Tu privacidad en RDReporta'),
        content: const Text(
          '• No rastreamos tu ubicación en segundo plano.\n\n'
          '• Las coordenadas se usan únicamente cuando decides consultar o publicar una incidencia.\n\n'
          '• No existen mensajes privados ni comentarios públicos.\n\n'
          '• Tu correo y los datos de tu cuenta no se muestran en las publicaciones.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    final initials = _user!.username.isNotEmpty
        ? _user!.username.substring(0, 1).toUpperCase()
        : 'RD';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        children: [
          _buildEditableAvatar(initials),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _avatarBusy ? null : _changeAvatar,
            icon: const Icon(Icons.image_outlined, size: 17),
            label: const Text('Cambiar foto'),
            style: TextButton.styleFrom(
              foregroundColor: context.loveColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _user!.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor),
                ),
              ),
              if (_user!.isVerified) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Perfil verificado por RDReporta',
                  child: Icon(Icons.verified_rounded,
                      size: 21, color: context.pineColor),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '@${_user!.username}',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.loveColor),
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
              border:
                  Border.all(color: context.loveColor.withValues(alpha: 0.25), width: 2),
            ),
            child: Text(
              'Nivel: ${_user!.reputationLevel}',
              style: TextStyle(
                  color: context.loveColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildStat('Reportes', '${_user!.totalPosts}')),
              Expanded(
                  child: _buildStat(
                      'Seguidores', '${_user!.followersCount}')),
              Expanded(
                  child: _buildStat(
                      'Siguiendo', '${_user!.followingCount}')),
            ],
          ),
          const SizedBox(height: 16),

          // Selector de Apariencia y tema (Rosé Pine)
          _buildThemeSelectorCard(),

          const SizedBox(height: 12),

          // Details List
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor, width: 2),
            ),
            child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.location_on_outlined,
                          color: context.pineColor),
                      title: Text(
                          'Provincia: ${_user!.province ?? "República Dominicana"}',
                          style: TextStyle(color: context.textPrimaryColor)),
                      subtitle: _user!.municipality != null
                          ? Text('Municipio: ${_user!.municipality}',
                              style: TextStyle(color: context.subtleColor))
                          : null,
                    ),
                    Divider(color: context.borderColor),
                    ListTile(
                      leading: Icon(Icons.calendar_today_outlined,
                          color: context.pineColor),
                      title: Text('Miembro desde',
                          style: TextStyle(color: context.textPrimaryColor)),
                      subtitle: Text(
                          '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}',
                          style: TextStyle(color: context.subtleColor)),
                    ),
                    Divider(color: context.borderColor),
                    ListTile(
                      leading: Icon(Icons.verified_user_outlined,
                          color: context.pineColor),
                      title: Text('Privacidad y comunidad',
                          style: TextStyle(color: context.textPrimaryColor)),
                      subtitle: Text('Conoce cómo protegemos tus datos',
                          style: TextStyle(
                              fontSize: 12, color: context.subtleColor)),
                      trailing:
                          Icon(Icons.chevron_right, color: context.mutedColor),
                      onTap: _showPrivacyDetails,
                    ),
                    Divider(color: context.borderColor),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Cerrar sesión',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w600)),
                      onTap: _logout,
                    ),
                  ],
                )),
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
          width: isDark ? 1.2 : 2,
        ),
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
                child: Icon(Icons.palette_outlined,
                    size: 20, color: context.loveColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apariencia y tema',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Personaliza los colores de la aplicación',
                      style:
                          TextStyle(fontSize: 12, color: context.subtleColor),
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
            width: 2,
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
                color:
                    isSelected ? context.loveColor : context.textPrimaryColor,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? context.loveColor.withValues(alpha: 0.85)
                    : context.mutedColor,
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
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor))),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: context.subtleColor)),
      ],
    );
  }
}
