import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/incident_card.dart';
import '../posts/create_post_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/location_service.dart';
import '../../shared/widgets/request_state.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../core/constants/api_constants.dart';
import '../notifications_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();

  List<PostModel> _forYouPosts = [];
  List<PostModel> _recentPosts = [];
  List<PostModel> _nearbyPosts = [];
  List<CategoryModel> _categories = [];
  int? _selectedCategory;
  bool _loading = true;
  String? _error;
  String? _locationError;
  Position? _position;
  bool _locating = false;
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _nearbyPage = 1;
  bool _nearbyHasMore = false;
  int _loadVersion = 0;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
    _loadCurrentUser();
    _apiClient.changes.addListener(_loadInitialData);
    _apiClient.changes.addListener(_loadCurrentUser);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiClient.changes.removeListener(_loadInitialData);
    _apiClient.changes.removeListener(_loadCurrentUser);
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _apiClient.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
  }

  String _avatarUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    return '${ApiConstants.hostUrl}/${value.replaceFirst(RegExp(r'^/'), '')}';
  }

  Widget _buildProfileAvatar() {
    final avatar = _currentUser?.avatarUrl;
    final initial = (_currentUser?.username.isNotEmpty ?? false)
        ? _currentUser!.username.substring(0, 1).toUpperCase()
        : null;
    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.overlayColor
            : const Color(0xFFFFFAF3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 2),
      ),
      child: avatar != null && avatar.isNotEmpty
          ? Image.network(
              _avatarUrl(avatar),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.person_rounded,
                color: context.loveColor,
              ),
            )
          : initial != null
              ? Text(
                  initial,
                  style: TextStyle(
                    color: context.loveColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Icon(
                  Icons.person_rounded,
                  color: context.loveColor,
                ),
    );
  }

  Future<void> _loadInitialData() async {
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _nearbyPage = 1;
    });
    try {
      final results = await Future.wait([
        _apiClient.getRecentPosts(categoryId: _selectedCategory),
        _position == null
            ? Future.value(<PostModel>[])
            : _apiClient.getNearbyPosts(
                latitude: _position!.latitude,
                longitude: _position!.longitude,
                categoryId: _selectedCategory),
        _apiClient.getCategories(),
        _apiClient.getPopularPosts(),
      ]);

      if (mounted && version == _loadVersion) {
        setState(() {
          _recentPosts = results[0] as List<PostModel>;
          _nearbyPosts = results[1] as List<PostModel>;
          _categories = results[2] as List<CategoryModel>;
          final popularPosts = results[3] as List<PostModel>;
          _forYouPosts = _selectedCategory == null
              ? popularPosts
              : popularPosts
                  .where((post) => post.categoryId == _selectedCategory)
                  .toList();
          if (_forYouPosts.isEmpty) {
            _forYouPosts = List<PostModel>.from(_recentPosts);
          }
          _hasMore = _recentPosts.length == 20;
          _nearbyHasMore = _nearbyPosts.length == 20;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && version == _loadVersion) {
        setState(() {
          _error = ApiClient.errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final position = await requestCurrentLocation();
      if (!mounted) return;
      setState(() {
        _position = position;
        _locationError = null;
      });
      await _loadInitialData();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _locationError = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _loadMore({bool nearby = false}) async {
    if (_loadingMore) {
      return;
    }
    setState(() => _loadingMore = true);
    final version = _loadVersion;
    try {
      final next = nearby
          ? await _apiClient.getNearbyPosts(
              latitude: _position!.latitude,
              longitude: _position!.longitude,
              page: _nearbyPage + 1,
              categoryId: _selectedCategory)
          : await _apiClient.getRecentPosts(
              page: _page + 1, categoryId: _selectedCategory);
      if (mounted && version == _loadVersion) {
        setState(() {
          if (nearby) {
            _nearbyPage++;
            _nearbyHasMore = next.length == 20;
          } else {
            _page++;
            _hasMore = next.length == 20;
          }
          final target = nearby ? _nearbyPosts : _recentPosts;
          final ids = target.map((p) => p.id).toSet();
          target.addAll(next.where((p) => !ids.contains(p.id)));
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
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 16,
        title: Row(
          children: [
            _buildProfileAvatar(),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RDReporta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: context.textPrimaryColor,
                  ),
                ),
                Text(
                  'Tu comunidad al día',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.subtleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: context.baseColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            icon: Icon(Icons.notifications_none_rounded, color: context.loveColor),
            onPressed: () async {
              if (!await requireSession(context) || !context.mounted) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
          Container(
            width: 46,
            height: 46,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor, width: 2),
            ),
            child: IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: context.loveColor,
                size: 21,
              ),
              tooltip: isDark
                  ? 'Cambiar a Rosé Pine Dawn (claro)'
                  : 'Cambiar a Rosé Pine (oscuro)',
              onPressed: AppTheme.toggleTheme,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            height: 50,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor, width: 2),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(2),
              indicator: BoxDecoration(
                color: context.overlayColor,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: context.loveColor, width: 2),
              ),
              labelColor: context.loveColor,
              unselectedLabelColor: context.mutedColor,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Para ti'),
                Tab(text: 'Cerca de mí'),
                Tab(text: 'Recientes'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category chips filter
          if (_categories.isNotEmpty)
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAll = _selectedCategory == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Todas'),
                        selected: isAll,
                        showCheckmark: false,
                        backgroundColor: context.overlayColor,
                        selectedColor: context.loveColor.withValues(alpha: 0.2),
                        side: BorderSide(
                          color:
                              isAll ? context.loveColor : context.borderColor,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isAll ? FontWeight.bold : FontWeight.normal,
                          color: isAll
                              ? context.loveColor
                              : context.textPrimaryColor,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedCategory = null);
                          _loadInitialData();
                        },
                      ),
                    );
                  }
                  final cat = _categories[index - 1];
                  final isSelected = _selectedCategory == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      showCheckmark: false,
                      backgroundColor: context.overlayColor,
                      selectedColor: context.loveColor.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: isSelected
                            ? context.loveColor
                            : context.borderColor,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? context.loveColor
                            : context.textPrimaryColor,
                      ),
                      onSelected: (_) {
                        setState(() =>
                            _selectedCategory = isSelected ? null : cat.id);
                        _loadInitialData();
                      },
                    ),
                  );
                },
              ),
            ),

          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: context.loveColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : _error != null
                    ? RequestState(message: _error!, onRetry: _loadInitialData)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPostList(_forYouPosts),
                          _position == null
                              ? RequestState(
                                  message: _locationError ??
                                      'Comparte tu ubicación para consultar incidencias cercanas.',
                                  onRetry: _locating ? () {} : _locate,
                                  action: _locating
                                      ? 'Obteniendo ubicación…'
                                      : 'Usar mi ubicación')
                              : _buildPostList(_nearbyPosts),
                          _buildPostList(_recentPosts),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(List<PostModel> posts) {
    return RefreshIndicator(
      color: context.loveColor,
      onRefresh: _loadInitialData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 90),
        children: [
          if (posts.isEmpty)
            _buildEmptyStateCard()
          else
            ...posts.map(
                (post) => IncidentCard(key: ValueKey(post.id), post: post)),
          if (identical(posts, _recentPosts) && _hasMore)
            TextButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: Text(_loadingMore ? 'Cargando…' : 'Ver más reportes')),
          if (identical(posts, _nearbyPosts) && _nearbyHasMore)
            TextButton(
                onPressed: _loadingMore ? null : () => _loadMore(nearby: true),
                child: Text(
                    _loadingMore ? 'Cargando…' : 'Ver más reportes cercanos')),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0x1AFFFFFF)
              : context.borderColor,
          width: context.isDarkMode ? 1.2 : 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: context.overlayColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 28,
              color: context.subtleColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Zona sin incidencias registradas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay reportes en esta categoría por el momento. Si observas una incidencia en tu sector, puedes reportarla con fotos y coordenadas GPS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: context.subtleColor,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () async {
              if (!await requireSession(context) || !mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreatePostScreen()),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Crear nuevo reporte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.loveColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
