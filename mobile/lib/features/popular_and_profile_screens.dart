import 'package:flutter/material.dart';
import '../core/networking/api_client.dart';
import '../core/theme/app_theme.dart';
import '../shared/models/models.dart';
import '../shared/widgets/incident_card.dart';
import 'auth/login_screen.dart';
import '../shared/widgets/request_state.dart';
import 'profile/edit_profile_screen.dart';
import 'profile/my_posts_screen.dart';
import '../core/constants/api_constants.dart';

PreferredSizeWidget _sectionHeader(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  List<Widget> actions = const [],
  Widget? leading,
  bool isVerified = false,
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
            leading ??
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified_rounded, size: 16, color: context.pineColor),
                      ],
                    ],
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

  Future<void> _loadPopular({bool isRefresh = false}) async {
    if (!isRefresh && _posts.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
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
      backgroundColor: context.baseColor,
      appBar: _sectionHeader(
          context,
          icon: Icons.local_fire_department_rounded,
          title: 'Popular esta semana',
          subtitle: 'Lo más relevante de la comunidad',
        ),
        body: _loading
            ? Center(
                child: CircularProgressIndicator(
                    color: context.loveColor, strokeWidth: 2.5))
            : RefreshIndicator(
                color: context.loveColor,
                backgroundColor: context.surfaceColor,
                displacement: 40.0,
                onRefresh: () => _loadPopular(isRefresh: true),
                child: _error != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.55,
                            child: RequestState(
                                message: _error!,
                                onRetry: () => _loadPopular(isRefresh: true)),
                          ),
                        ],
                      )
                    : _posts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Center(
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
                                            fontSize: 13,
                                            color: context.subtleColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 140),
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

  String _avatarUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    return '${ApiConstants.hostUrl}/${value.replaceFirst(RegExp(r'^/'), '')}';
  }

  Widget _buildEditableAvatar(String initials) {
    final avatar = _user?.avatarUrl;
    return Container(
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
              child: avatar != null && avatar.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(5),
                          child: ClipOval(
                            child: Image.network(
                              _avatarUrl(avatar),
                              width: 82,
                              height: 82,
                              cacheWidth: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                initials,
                                style: TextStyle(
                                  color: context.loveColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  Future<void> _loadProfile({bool isRefresh = false}) async {
    if (!isRefresh && _user == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
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
        backgroundColor: context.baseColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
            'Tendrás que volver a iniciar sesión para confirmar incidencias o publicar reportes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: context.textPrimaryColor,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.goldColor,
              foregroundColor: context.isDarkMode ? Colors.black : Colors.white,
            ),
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

  Future<void> _deleteAccount() async {
    // First confirmation dialog
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.baseColor,
        surfaceTintColor: Colors.transparent,
        icon: Icon(Icons.warning_amber_rounded,
            color: Colors.red.shade400, size: 40),
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
          'Esta acción es permanente e irreversible. Se eliminarán todos tus datos:\n\n'
          '• Todos tus reportes y fotos\n'
          '• Tus reacciones y seguidores\n'
          '• Tu perfil completo\n\n'
          'No podrás recuperar esta información.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: context.textPrimaryColor,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted) return;

    // Second confirmation: type ELIMINAR
    final confirmController = TextEditingController();
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.baseColor,
          surfaceTintColor: Colors.transparent,
          title: const Text('Confirmación final'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escribe ELIMINAR para confirmar que deseas borrar tu cuenta permanentemente.',
                style: TextStyle(color: context.subtleColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ELIMINAR',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: TextButton.styleFrom(
                foregroundColor: context.textPrimaryColor,
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: confirmController.text.trim().toUpperCase() == 'ELIMINAR'
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text('Eliminar mi cuenta'),
            ),
          ],
        ),
      ),
    );

    confirmController.dispose();
    if (secondConfirm != true || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _apiClient.deleteAccount();
      if (mounted) {
        Navigator.pop(context); // dismiss loading
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.baseColor,
      appBar: _sectionHeader(
          context,
          icon: Icons.person_rounded,
          title: _user?.displayName ?? 'Perfil',
          subtitle: _user == null ? 'Cuenta y preferencias' : '@${_user!.username}',
          isVerified: _user?.isVerified ?? false,
          leading: _user?.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
              ? Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(2),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? context.overlayColor
                        : const Color(0xFFFFFAF3),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.borderColor, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      _avatarUrl(_user!.avatarUrl!),
                      cacheWidth: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: context.loveColor,
                        size: 20,
                      ),
                    ),
                  ),
                )
              : null,
          actions: [
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
            : RefreshIndicator(
                color: context.loveColor,
                backgroundColor: context.surfaceColor,
                displacement: 40.0,
                onRefresh: () => _loadProfile(isRefresh: true),
                child: _error != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.55,
                            child: RequestState(
                                message: _error!,
                                onRetry: () => _loadProfile(isRefresh: true)),
                          ),
                        ],
                      )
                    : (_user != null
                        ? _buildUserProfile()
                        : const SizedBox.shrink()),
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
      // Leave room for the navigation bar and its new top margin when scrolling.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        children: [
          _buildEditableAvatar(initials),
          const SizedBox(height: 12),
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
                    if (_user!.province?.trim().isNotEmpty == true) ...[
                      ListTile(
                        leading: Icon(Icons.location_on_outlined, color: context.pineColor),
                        title: Text('Provincia: ${_user!.province}', style: TextStyle(color: context.textPrimaryColor)),
                      ),
                      Divider(color: context.borderColor),
                    ],                    ListTile(
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
                      leading: Icon(Icons.delete_forever_rounded,
                          color: context.loveColor),
                      title: Text('Eliminar mi cuenta',
                          style: TextStyle(
                              color: context.loveColor,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text('Elimina permanentemente tu cuenta y todos tus datos',
                          style: TextStyle(
                              fontSize: 11, color: context.mutedColor)),
                      onTap: _deleteAccount,
                    ),
                    Divider(color: context.borderColor),
                    ListTile(
                      leading: Icon(Icons.logout, color: context.goldColor),
                      title: Text('Cerrar sesión',
                          style: TextStyle(
                              color: context.goldColor,
                              fontWeight: FontWeight.w600)),
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
