import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../feed/feed_screen.dart';
import '../map/map_screen.dart';
import '../posts/create_post_screen.dart';
import '../popular_and_profile_screens.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../core/firebase_service.dart';
import '../../core/networking/api_client.dart';
import '../feed/post_detail_screen.dart';
import '../notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _notificationTimer;
  StreamSubscription<RemoteMessage>? _messages;
  final _api = ApiClient();

  final List<Widget> _screens = const [
    FeedScreen(),
    MapScreen(),
    PopularScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _api.sessionChanges.addListener(_refreshNotifications);
    FirebaseService.pendingOpen.addListener(_onPendingOpen);
    _messages = FirebaseService.messages.stream.listen(_showNotification);
    _resumeNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPendingOpen());
  }

  void _refreshNotifications() {
    unawaited(_api.refreshUnreadNotifications());
  }

  void _resumeNotifications() {
    _refreshNotifications();
    unawaited(FirebaseService.syncToken());
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _refreshNotifications());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeNotifications();
    } else {
      _notificationTimer?.cancel();
    }
  }

  Future<bool> _belongsToSession(RemoteMessage message) async {
    if (!await _api.isLoggedIn()) return false;
    final recipient = message.data['userId'];
    return recipient != null && recipient == await _api.getCurrentUserId();
  }

  Future<void> _showNotification(RemoteMessage message) async {
    if (!await _belongsToSession(message) || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(message.notification?.body ?? 'Tienes una nueva notificación.'),
      action: SnackBarAction(label: 'Ver', onPressed: () => _openPush(message)),
    ));
  }

  void _onPendingOpen() {
    final message = FirebaseService.pendingOpen.value;
    if (message == null || !mounted) return;
    FirebaseService.pendingOpen.value = null;
    unawaited(_openPush(message));
  }

  Future<void> _openPush(RemoteMessage message) async {
    if (!await _belongsToSession(message) || !mounted) return;
    final postId = message.data['postId'];
    final notificationId = message.data['notificationId'];
    if (notificationId is String) {
      try {
        await _api.markNotificationsRead([notificationId]);
      } catch (_) {}
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => postId is String && postId.isNotEmpty
          ? PostDetailScreen(postId: postId)
          : const NotificationsScreen(),
    ));
    _refreshNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationTimer?.cancel();
    _messages?.cancel();
    _api.sessionChanges.removeListener(_refreshNotifications);
    FirebaseService.pendingOpen.removeListener(_onPendingOpen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.baseColor,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildModernBottomBar(context),
    );
  }

  Widget _buildModernBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        // Keep a clear visual gap between screen content and the navigation.
        margin: const EdgeInsets.fromLTRB(12, 32, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.borderColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0: Inicio (Categorías / Feed)
            _buildNavItem(
              outlineIcon: Icons.home_outlined,
              filledIcon: Icons.home_rounded,
              label: 'Inicio',
              index: 0,
            ),

            // Tab 1: Mapa (Radar)
            _buildNavItem(
              outlineIcon: Icons.map_outlined,
              filledIcon: Icons.map_rounded,
              label: 'Mapa',
              index: 1,
            ),

            // Acción principal para crear un reporte.
            _buildCenterActionButton(context),

            // Tab 2: Popular
            _buildNavItem(
              outlineIcon: Icons.local_fire_department_outlined,
              filledIcon: Icons.local_fire_department_rounded,
              label: 'Popular',
              index: 2,
            ),

            // Tab 3: Perfil
            _buildNavItem(
              outlineIcon: Icons.person_outline_rounded,
              filledIcon: Icons.person_rounded,
              label: 'Perfil',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (!await requireSession(context) || !context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        );
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: context.loveColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.surfaceColor, width: 2),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 29,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData outlineIcon,
    required IconData filledIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = context.loveColor;
    final inactiveColor = context.mutedColor;

    return Expanded(
        child: InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12.0 : 8.0,
          vertical: 7.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? context.overlayColor : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? context.loveColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 21,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
