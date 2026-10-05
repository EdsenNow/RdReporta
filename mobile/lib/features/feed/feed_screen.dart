import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/incident_card.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/location_service.dart';
import '../../shared/widgets/request_state.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../shared/widgets/rdreporta_logo.dart';
import '../../core/constants/api_constants.dart';
import '../notifications_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late AnimationController _headerAnimController;
  late Animation<double> _headerAnim;
  double _accumulatedDelta = 0.0;
  int _prevTabIndex = 0;
  final ApiClient _apiClient = ApiClient();

  List<PostModel> _forYouPosts = [];
  List<PostModel> _recentPosts = [];
  List<PostModel> _nearbyPosts = [];
  List<CategoryModel> _categories = [];
  int? _selectedCategory;
  bool _loading = true;
  String? _error;
  String? _locationError;
  LocationSettingsAction? _locationSettingsAction;
  Position? _position;
  bool _locating = false;
  bool _loadingNearby = false;
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _nearbyPage = 1;
  bool _nearbyHasMore = false;
  int _loadVersion = 0;
  int _nearbyVersion = 0;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _headerAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeInOut,
    );
    _loadInitialData();
    _loadCurrentUser();
    _apiClient.changes.addListener(_loadInitialData);
    _apiClient.changes.addListener(_loadCurrentUser);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _headerAnimController.dispose();
    _apiClient.changes.removeListener(_loadInitialData);
    _apiClient.changes.removeListener(_loadCurrentUser);
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index != _prevTabIndex) {
      _prevTabIndex = _tabController.index;
      _showTopMenu();
      if (_tabController.index == 1 && _position == null) {
        unawaited(_locate());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tabController.index == 1) {
      unawaited(_locate());
    }
  }

  void _showTopMenu() {
    if (_headerAnimController.status != AnimationStatus.forward &&
        _headerAnimController.value < 1.0) {
      _headerAnimController.forward();
    }
  }

  void _hideTopMenu() {
    if (_headerAnimController.status != AnimationStatus.reverse &&
        _headerAnimController.value > 0.0) {
      _headerAnimController.reverse();
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    // If at the top of the feed or overscrolling at the top, ALWAYS show the top menu
    if (notification.metrics.pixels <= 0.0) {
      _showTopMenu();
      _accumulatedDelta = 0.0;
      return false;
    }

    // If content cannot be scrolled (empty or very short list), keep header visible
    if (notification.metrics.maxScrollExtent <= 50) {
      _showTopMenu();
      _accumulatedDelta = 0.0;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      // User active finger drag
      if (notification.dragDetails != null) {
        final delta = notification.scrollDelta ?? 0.0;
        if (delta > 0) {
          // Scrolling down: accumulate positive delta
          if (_accumulatedDelta < 0) _accumulatedDelta = 0;
          _accumulatedDelta += delta;
          if (_accumulatedDelta > 15.0) {
            _hideTopMenu();
          }
        } else if (delta < 0) {
          // Scrolling up: accumulate negative delta
          if (_accumulatedDelta > 0) _accumulatedDelta = 0;
          _accumulatedDelta += delta;
          if (_accumulatedDelta < -15.0) {
            _showTopMenu();
          }
        }
      } else {
        // Fast fling / inertial scroll upwards
        final delta = notification.scrollDelta ?? 0.0;
        if (delta < -25.0) {
          _showTopMenu();
        }
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        _showTopMenu();
      }
    } else if (notification is ScrollEndNotification) {
      _accumulatedDelta = 0.0;
    }
    return false;
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
        color:
            context.isDarkMode ? context.overlayColor : const Color(0xFFFFFAF3),
        shape: BoxShape.circle,
        border: Border.all(color: context.borderColor, width: 2),
      ),
      child: avatar != null && avatar.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: Image.network(
                  _avatarUrl(avatar),
                  width: 36,
                  height: 36,
                  cacheWidth: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person_rounded,
                    color: context.loveColor,
                  ),
                ),
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

  Future<void> _loadInitialData({bool isRefresh = false}) async {
    final version = ++_loadVersion;
    final nearbyLoad =
        _position == null || _locating ? Future<void>.value() : _loadNearby();
    if (!isRefresh && _forYouPosts.isEmpty && _recentPosts.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _nearbyPage = 1;
      });
    } else {
      setState(() {
        _error = null;
        _page = 1;
        _nearbyPage = 1;
      });
    }
    try {
      final results = await Future.wait([
        _apiClient.getRecentPosts(categoryId: _selectedCategory),
        _apiClient.getCategories(),
        _apiClient.getPopularPosts(),
      ]);

      if (mounted && version == _loadVersion) {
        setState(() {
          _recentPosts = results[0] as List<PostModel>;
          _categories = results[1] as List<CategoryModel>;
          final popularPosts = results[2] as List<PostModel>;
          _forYouPosts = _selectedCategory == null
              ? popularPosts
              : popularPosts
                  .where((post) => post.categoryId == _selectedCategory)
                  .toList();
          if (_forYouPosts.isEmpty) {
            _forYouPosts = List<PostModel>.from(_recentPosts);
          }
          _hasMore = _recentPosts.length == 20;
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
    await nearbyLoad;
  }

  Future<void> _locate() async {
    if (_locating || _loadingNearby) return;
    ++_nearbyVersion;
    setState(() {
      _locating = true;
      _locationError = null;
      _locationSettingsAction = null;
    });
    try {
      final position = await requestCurrentLocation();
      if (!mounted) return;
      setState(() {
        _position = position;
        _locationError = null;
        _locationSettingsAction = null;
        _locating = false;
      });
      await _loadNearby();
    } catch (e) {
      if (mounted) {
        setState(() {
          final locationFailure = e is LocationRequestException ? e : null;
          if (locationFailure?.settingsAction != null) {
            _position = null;
            _locationError = e.toString().replaceFirst('Exception: ', '');
            _locationSettingsAction = locationFailure!.settingsAction;
          } else if (_position == null) {
            _locationError = e.toString().replaceFirst('Exception: ', '');
            _locationSettingsAction = null;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _handleLocationAction() async {
    switch (_locationSettingsAction) {
      case LocationSettingsAction.app:
        await Geolocator.openAppSettings();
        return;
      case LocationSettingsAction.location:
        await Geolocator.openLocationSettings();
        return;
      case null:
        await _locate();
        return;
    }
  }

  Future<void> _loadNearby() async {
    final position = _position;
    if (position == null) return;
    final version = ++_nearbyVersion;
    setState(() {
      _loadingNearby = true;
      _locationError = null;
    });
    try {
      final posts = await _apiClient.getNearbyPosts(
        latitude: position.latitude,
        longitude: position.longitude,
        categoryId: _selectedCategory,
      );
      if (mounted && version == _nearbyVersion) {
        setState(() {
          _nearbyPosts = posts;
          _nearbyPage = 1;
          _nearbyHasMore = posts.length == 20;
        });
      }
    } catch (e) {
      if (mounted && version == _nearbyVersion) {
        setState(() => _locationError = ApiClient.errorMessage(e));
      }
    } finally {
      if (mounted && version == _nearbyVersion) {
        setState(() {
          _loadingNearby = false;
        });
      }
    }
  }

  Future<void> _loadMore({bool nearby = false}) async {
    if (_loadingMore || (nearby && (_loadingNearby || _locating))) {
      return;
    }
    setState(() => _loadingMore = true);
    final version = _loadVersion;
    final nearbyVersion = _nearbyVersion;
    try {
      final next = nearby
          ? await _apiClient.getNearbyPosts(
              latitude: _position!.latitude,
              longitude: _position!.longitude,
              page: _nearbyPage + 1,
              categoryId: _selectedCategory)
          : await _apiClient.getRecentPosts(
              page: _page + 1, categoryId: _selectedCategory);
      if (mounted &&
          version == _loadVersion &&
          (!nearby || nearbyVersion == _nearbyVersion)) {
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

  Widget _buildTopMenu(BuildContext context, bool isDark) {
    return Container(
      color: context.baseColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Row(
              children: [
                _buildProfileAvatar(),
                const SizedBox(width: 11),
                Expanded(
                  child: Row(
                    children: [
                      const RdReportaLogo(size: 38),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'RDReporta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            Text(
                              'Tu comunidad al día',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.subtleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _apiClient.unreadNotifications,
                  builder: (context, count, _) => IconButton(
                    tooltip: count == 0
                        ? 'Notificaciones'
                        : 'Notificaciones: $count pendientes',
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text(count > 99 ? '99+' : '$count'),
                      backgroundColor: context.loveColor,
                      textColor: const Color(0xFF191724),
                      child: Icon(
                        Icons.notifications_rounded,
                        color: context.loveColor,
                        size: 24,
                      ),
                    ),
                    onPressed: () async {
                      if (!await requireSession(context) || !context.mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                      await _apiClient.refreshUnreadNotifications();
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return Container(
      height: 52,
      color: context.baseColor,
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
                backgroundColor: context.surfaceColor,
                selectedColor: context.loveColor,
                side: BorderSide(
                  width: 2,
                  color: isAll ? context.loveColor : context.borderColor,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isAll ? FontWeight.bold : FontWeight.normal,
                  color: isAll ? Colors.white : context.textPrimaryColor,
                ),
                onSelected: (_) {
                  setState(() => _selectedCategory = null);
                  _showTopMenu();
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
              backgroundColor: context.surfaceColor,
              selectedColor: context.loveColor,
              side: BorderSide(
                width: 2,
                color: isSelected ? context.loveColor : context.borderColor,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : context.textPrimaryColor,
              ),
              onSelected: (_) {
                setState(() => _selectedCategory = isSelected ? null : cat.id);
                _showTopMenu();
                _loadInitialData();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: context.baseColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top menu (Avatar, title, actions, TabBar) that collapses when scrolling down and reappears when scrolling up
                SizeTransition(
                  sizeFactor: _headerAnim,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: _headerAnim,
                    child: _buildTopMenu(context, isDark),
                  ),
                ),

                // Scrollable feed content
                Expanded(
                  child: RefreshIndicator(
                    color: context.loveColor,
                    backgroundColor: context.surfaceColor,
                    displacement: 40.0,
                    edgeOffset: 0.0,
                    notificationPredicate: (notification) =>
                        notification.metrics.axis == Axis.vertical,
                    onRefresh: () => _tabController.index == 1
                        ? _locate()
                        : _loadInitialData(isRefresh: true),
                    child: _loading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: context.loveColor,
                              strokeWidth: 2.5,
                            ),
                          )
                        : _error != null
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  if (_categories.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 6, bottom: 6),
                                      child: _buildCategoryChips(context),
                                    ),
                                  SizedBox(
                                    height: screenHeight * 0.55,
                                    child: RequestState(
                                      message: _error!,
                                      onRetry: () =>
                                          _loadInitialData(isRefresh: true),
                                    ),
                                  ),
                                ],
                              )
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildPostList(_forYouPosts),
                                  _buildNearby(),
                                  _buildPostList(_recentPosts),
                                ],
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

  Widget _buildNearby() {
    if (_locating || _loadingNearby) {
      return Center(child: CircularProgressIndicator(color: context.loveColor));
    }
    if (_position == null || _locationError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: _buildCategoryChips(context),
            ),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: RequestState(
              message: _locationError ??
                  'Comparte tu ubicación para consultar reportes a menos de 10 km.',
              onRetry: _handleLocationAction,
              action: switch (_locationSettingsAction) {
                LocationSettingsAction.app => 'Abrir permisos',
                LocationSettingsAction.location => 'Activar ubicación',
                null => 'Volver a intentar',
              },
            ),
          ),
        ],
      );
    }
    return _buildPostList(_nearbyPosts);
  }

  Widget _buildPostList(List<PostModel> posts) {
    final bool hasCategories = _categories.isNotEmpty;
    final bool isNearby = identical(posts, _nearbyPosts);
    final bool isRecent = identical(posts, _recentPosts);
    final bool showLoadMoreRecent = isRecent && _hasMore;
    final bool showLoadMoreNearby = isNearby && _nearbyHasMore;
    final bool showEmptyState = posts.isEmpty;

    int topItemCount = (hasCategories ? 1 : 0) + (isNearby ? 1 : 0);
    int bottomItemCount = (showLoadMoreRecent || showLoadMoreNearby ? 1 : 0);
    int totalCount = topItemCount + (showEmptyState ? 1 : posts.length) + bottomItemCount;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 105),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        int currentIndex = index;

        if (hasCategories) {
          if (currentIndex == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildCategoryChips(context),
            );
          }
          currentIndex--;
        }

        if (isNearby) {
          if (currentIndex == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Reportes a menos de 10 km',
                        style: TextStyle(color: context.subtleColor)),
                  ),
                  IconButton(
                    tooltip: 'Actualizar mi ubicación',
                    onPressed: _locate,
                    icon: Icon(Icons.my_location_rounded, color: context.pineColor),
                  ),
                ],
              ),
            );
          }
          currentIndex--;
        }

        if (showEmptyState) {
          if (currentIndex == 0) {
            return _buildEmptyStateCard(nearby: isNearby);
          }
          currentIndex--;
        } else {
          if (currentIndex < posts.length) {
            final post = posts[currentIndex];
            return IncidentCard(key: ValueKey(post.id), post: post);
          }
          currentIndex -= posts.length;
        }

        if (showLoadMoreRecent) {
          if (currentIndex == 0) {
            return TextButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: Text(_loadingMore ? 'Cargando…' : 'Ver más reportes'));
          }
        }

        if (showLoadMoreNearby) {
          if (currentIndex == 0) {
            return TextButton(
                onPressed: _loadingMore ? null : () => _loadMore(nearby: true),
                child: Text(_loadingMore ? 'Cargando…' : 'Ver más reportes cercanos'));
          }
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyStateCard({bool nearby = false}) {
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
          width: 2,
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
            nearby
                ? 'No hay reportes cercanos'
                : 'Zona sin incidencias registradas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nearby
                ? 'No encontramos reportes con coordenadas en esta categoría a menos de 10 km de tu ubicación.'
                : 'No hay reportes en esta categoría por el momento. Puedes publicar uno con el botón +.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: context.subtleColor,
            ),
          ),
        ],
      ),
    );
  }
}
