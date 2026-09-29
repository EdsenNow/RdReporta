import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../feed/feed_screen.dart';
import '../map/map_screen.dart';
import '../posts/create_post_screen.dart';
import '../popular_and_profile_screens.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../core/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    MapScreen(),
    PopularScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    FirebaseService.syncToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
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
