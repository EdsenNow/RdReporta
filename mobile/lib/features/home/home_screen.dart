import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../feed/feed_screen.dart';
import '../map/map_screen.dart';
import '../posts/create_post_screen.dart';
import '../popular_and_profile_screens.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFinanzAppBottomBar(context),
    );
  }

  Widget _buildFinanzAppBottomBar(BuildContext context) {
    final isDark = context.isDarkMode;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? const Color(0x33EB6F92) : context.borderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0: Inicio (Categorías / Feed)
            _buildNavItem(
              outlineIcon: Icons.grid_view_outlined,
              filledIcon: Icons.grid_view_rounded,
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

            // Central Floating + Action Button (FinanzApp style)
            _buildCenterActionButton(context),

            // Tab 2: Popular
            _buildNavItem(
              outlineIcon: Icons.pie_chart_outline_rounded,
              filledIcon: Icons.pie_chart_rounded,
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        );
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: context.loveColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.loveColor.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
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

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12.0 : 8.0,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? context.overlayColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
